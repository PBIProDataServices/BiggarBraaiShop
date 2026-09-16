export type Category = 'Beef' | 'Lamb' | 'Pork' | 'Chicken' | 'Braai extras'

export type Product = {
  id: number
  name: string
  cut: string
  category: Category
  price: number
  unit: string
  partner: string
  suburb: string
  distance: number
  stock: number
  image: string
  subscriberOnly?: boolean
  featured?: boolean
}

export const categories: Category[] = ['Beef', 'Lamb', 'Pork', 'Chicken', 'Braai extras']

export const products: Product[] = [
  {
    id: 1,
    name: 'Premium Boerewors',
    cut: 'Traditional coriander',
    category: 'Beef',
    price: 129.99,
    unit: 'kg',
    partner: 'Karoo Craft Butchery',
    suburb: 'Stellenbosch',
    distance: 2.4,
    stock: 14,
    image: 'https://images.unsplash.com/photo-1607623814075-e51df1bdc82f?auto=format&fit=crop&w=900&q=80',
    featured: true,
  },
  {
    id: 2,
    name: 'Lamb Braai Chops',
    cut: 'Free-range loin chops',
    category: 'Lamb',
    price: 189.5,
    unit: 'kg',
    partner: 'Winelands Meat Co.',
    suburb: 'Paarl',
    distance: 8.7,
    stock: 7,
    image: 'https://images.unsplash.com/photo-1603048297172-c92544798d5a?auto=format&fit=crop&w=900&q=80',
  },
  {
    id: 3,
    name: 'Dry-aged Ribeye',
    cut: '28-day matured',
    category: 'Beef',
    price: 279.99,
    unit: 'kg',
    partner: 'The Block Butcher',
    suburb: 'Somerset West',
    distance: 11.2,
    stock: 4,
    image: 'https://images.unsplash.com/photo-1588347818036-558601350947?auto=format&fit=crop&w=900&q=80',
    subscriberOnly: true,
    featured: true,
  },
  {
    id: 4,
    name: 'Peri-peri Flatties',
    cut: 'Ready to braai',
    category: 'Chicken',
    price: 89.99,
    unit: 'each',
    partner: 'Farmhouse Foods',
    suburb: 'Kuils River',
    distance: 14.5,
    stock: 11,
    image: 'https://images.unsplash.com/photo-1532550907401-a500c9a57435?auto=format&fit=crop&w=900&q=80',
  },
  {
    id: 5,
    name: 'Pork Belly Rashers',
    cut: 'Thick cut, oak smoked',
    category: 'Pork',
    price: 119.99,
    unit: 'kg',
    partner: 'Oak & Ember Deli',
    suburb: 'Durbanville',
    distance: 19.3,
    stock: 9,
    image: 'https://images.unsplash.com/photo-1529692236671-f1f6cf9683ba?auto=format&fit=crop&w=900&q=80',
  },
  {
    id: 6,
    name: 'Wagyu Burger Patties',
    cut: 'Four 180g patties',
    category: 'Beef',
    price: 169.0,
    unit: 'pack',
    partner: 'The Block Butcher',
    suburb: 'Somerset West',
    distance: 11.2,
    stock: 3,
    image: 'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=900&q=80',
    subscriberOnly: true,
  },
  {
    id: 7,
    name: 'Braai Broodjies',
    cut: 'Cheese, tomato & onion',
    category: 'Braai extras',
    price: 64.99,
    unit: '6 pack',
    partner: 'Farmhouse Foods',
    suburb: 'Kuils River',
    distance: 14.5,
    stock: 18,
    image: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=900&q=80',
  },
  {
    id: 8,
    name: 'Sosatie Selection',
    cut: 'Beef & apricot marinade',
    category: 'Beef',
    price: 139.99,
    unit: 'kg',
    partner: 'Karoo Craft Butchery',
    suburb: 'Stellenbosch',
    distance: 2.4,
    stock: 6,
    image: 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?auto=format&fit=crop&w=900&q=80',
  },
]
