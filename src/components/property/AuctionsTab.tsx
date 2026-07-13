import React from 'react';
import { PropertyFile, Auction, generateId } from '../../db/schema';
import EditableRecordList, { FieldConfig } from './EditableRecordList';

// Manual entry only — the automated auction crawler/scraper from the old
// Flutter build was dropped per your call (unused, brittle, tied to specific
// county sites). This is just a plain record of auction dates/results.
const FIELDS: FieldConfig[] = [
  { key: 'place', label: 'Place', type: 'text' },
  { key: 'openingBid', label: 'Opening Bid', type: 'number', width: '120px' },
  { key: 'salesAmount', label: 'Sale Amount', type: 'number', width: '120px' },
  { key: 'auctionCompleted', label: 'Completed', type: 'checkbox', width: '90px' },
];

export default function AuctionsTab({
  property,
  onChange,
}: {
  property: PropertyFile;
  onChange: (patch: Partial<PropertyFile>) => void;
}) {
  return (
    <EditableRecordList<Auction>
      records={property.auctions}
      fields={FIELDS}
      onChange={(auctions) => onChange({ auctions })}
      newRecord={() => ({
        id: generateId('auction'),
        auctionDate: Date.now(),
        place: '',
        timeHour: 10,
        timeMinute: 0,
        auctionCompleted: false,
      })}
      emptyLabel="No auctions/sale dates yet."
      addLabel="+ Add Auction"
    />
  );
}
