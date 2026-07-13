import React, { useEffect, useState } from 'react';
import { DocumentCategory } from '../db/documentCategories';
import {
  DocumentTemplate,
  TemplateField,
  getTemplatesForCategory,
  saveTemplate,
  deleteTemplate,
} from '../db/documentTemplates';

// Lets you build a county-specific field list for the Document Reader —
// "every county does it differently" made concrete. A new override never
// touches the plain default template for the category, and the Document
// Reader's resolveTemplate() picks the most specific match (county > state >
// default) automatically, so adding one is purely additive.

interface Props {
  categories: DocumentCategory[];
}

export default function ExtractionTemplatesPanel({ categories }: Props) {
  const [categoryKey, setCategoryKey] = useState('');
  const [templates, setTemplates] = useState<DocumentTemplate[]>([]);
  const [expandedId, setExpandedId] = useState<string | null>(null);
  const [newState, setNewState] = useState('');
  const [newCounty, setNewCounty] = useState('');

  useEffect(() => {
    if (categories[0] && !categoryKey) setCategoryKey(categories[0].key);
  }, [categories, categoryKey]);

  useEffect(() => {
    if (!categoryKey) return;
    getTemplatesForCategory(categoryKey).then(setTemplates);
  }, [categoryKey]);

  const defaultTemplate = templates.find((t) => !t.state && !t.county);

  async function handleAddOverride() {
    if (!defaultTemplate) {
      alert("This category has no default template to start from yet — add fields to it first.");
      return;
    }
    if (!newState.trim() || !newCounty.trim()) {
      alert('Enter both a state and a county for the override.');
      return;
    }
    const created = await saveTemplate({
      categoryKey,
      state: newState.trim().toUpperCase(),
      county: newCounty.trim(),
      applyTarget: defaultTemplate.applyTarget,
      fields: defaultTemplate.fields.map((f) => ({ ...f })),
    });
    setTemplates((prev) => [...prev, created]);
    setExpandedId(created.id);
    setNewState('');
    setNewCounty('');
  }

  async function handleFieldChange(template: DocumentTemplate, index: number, patch: Partial<TemplateField>) {
    const fields = template.fields.map((f, i) => (i === index ? { ...f, ...patch } : f));
    const updated = { ...template, fields };
    await saveTemplate(updated);
    setTemplates((prev) => prev.map((t) => (t.id === updated.id ? updated : t)));
  }

  async function handleAddField(template: DocumentTemplate) {
    const key = prompt('Field key (used internally, e.g. "legalDescription"):');
    if (!key) return;
    const label = prompt('Field label (shown to you / given to the AI):', key) || key;
    const updated = { ...template, fields: [...template.fields, { key, label }] };
    await saveTemplate(updated);
    setTemplates((prev) => prev.map((t) => (t.id === updated.id ? updated : t)));
  }

  async function handleRemoveField(template: DocumentTemplate, index: number) {
    const updated = { ...template, fields: template.fields.filter((_, i) => i !== index) };
    await saveTemplate(updated);
    setTemplates((prev) => prev.map((t) => (t.id === updated.id ? updated : t)));
  }

  async function handleDeleteOverride(template: DocumentTemplate) {
    if (!window.confirm(`Remove the ${template.county}, ${template.state} override? The Document Reader will fall back to the default template for this category.`)) return;
    await deleteTemplate(template.id);
    setTemplates((prev) => prev.filter((t) => t.id !== template.id));
  }

  return (
    <section>
      <h3 style={{ color: 'var(--text-primary)', fontSize: 15 }}>Extraction Templates</h3>
      <p style={{ color: 'var(--text-muted)', fontSize: 13, marginBottom: 12 }}>
        These are the fields the Document Reader asks the AI to pull out of each category's
        documents. Add a county-specific override when a county's tax cards (or deeds, etc.)
        are laid out differently — the Document Reader always uses the most specific match.
      </p>

      <select value={categoryKey} onChange={(e) => setCategoryKey(e.target.value)} style={{ marginBottom: 14, minWidth: 180 }}>
        {categories.map((c) => (
          <option key={c.key} value={c.key}>
            {c.label}
          </option>
        ))}
      </select>

      {templates.map((t) => {
        const isDefault = !t.state && !t.county;
        const label = isDefault ? 'Default (all states/counties)' : `${t.county}, ${t.state}`;
        const expanded = expandedId === t.id;
        return (
          <div key={t.id} style={{ border: '1px solid var(--border)', borderRadius: 8, marginBottom: 10, overflow: 'hidden' }}>
            <div
              onClick={() => setExpandedId(expanded ? null : t.id)}
              style={{
                padding: '10px 14px',
                background: 'var(--bg-card)',
                cursor: 'pointer',
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
              }}
            >
              <span style={{ color: 'var(--text-primary)', fontSize: 14, fontWeight: 600 }}>{label}</span>
              <span style={{ color: 'var(--text-muted)', fontSize: 12 }}>{t.fields.length} fields</span>
            </div>
            {expanded && (
              <div style={{ padding: 14 }}>
                {t.fields.map((f, i) => (
                  <div key={i} style={{ display: 'flex', gap: 8, marginBottom: 8, alignItems: 'center' }}>
                    <input
                      value={f.label}
                      onChange={(e) => handleFieldChange(t, i, { label: e.target.value })}
                      style={{ width: 160 }}
                    />
                    <input
                      placeholder="Extra guidance for the AI (optional)"
                      value={f.description || ''}
                      onChange={(e) => handleFieldChange(t, i, { description: e.target.value })}
                      style={{ flex: 1 }}
                    />
                    <button
                      onClick={() => handleRemoveField(t, i)}
                      style={{ background: 'none', border: 'none', color: 'var(--accent-red)', fontSize: 16 }}
                    >
                      ×
                    </button>
                  </div>
                ))}
                <div style={{ display: 'flex', gap: 8, marginTop: 8 }}>
                  <button
                    onClick={() => handleAddField(t)}
                    style={{ background: 'none', border: '1px dashed var(--border)', color: 'var(--text-secondary)', borderRadius: 6, padding: '6px 12px', fontSize: 12 }}
                  >
                    + Add Field
                  </button>
                  {!isDefault && (
                    <button
                      onClick={() => handleDeleteOverride(t)}
                      style={{ background: 'none', border: '1px solid var(--accent-red)', color: 'var(--accent-red)', borderRadius: 6, padding: '6px 12px', fontSize: 12 }}
                    >
                      Remove Override
                    </button>
                  )}
                </div>
              </div>
            )}
          </div>
        );
      })}

      <div style={{ display: 'flex', gap: 8, marginTop: 12 }}>
        <input placeholder="State (e.g. OR)" value={newState} onChange={(e) => setNewState(e.target.value)} style={{ width: 100 }} />
        <input placeholder="County (e.g. Multnomah)" value={newCounty} onChange={(e) => setNewCounty(e.target.value)} style={{ flex: 1 }} />
        <button className="btn-primary" onClick={handleAddOverride}>
          + Add County Override
        </button>
      </div>
    </section>
  );
}
