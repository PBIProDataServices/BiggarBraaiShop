# Biggar Braai Shop

A responsive customer storefront for finding and reserving braai stock from registered Biggar Braai partners.

## Features

- Search and filter partner stock by product, category, location and access level
- Partner name, suburb, distance, availability and map link on every item
- Inner Circle subscription with 10% member pricing and restricted-stock access
- Shopping bag with stock-aware quantities and member savings
- Responsive desktop and mobile layouts

## Development

```bash
npm install
npm run dev
```

Run the quality checks with:

```bash
npm test
npm run lint
npm run build
```

The current inventory is representative local data in `src/data.ts`. Production integration will need the Admin/Partner API contract, authentication and payment provider configuration.
