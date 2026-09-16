import { useMemo, useState } from 'react'
import {
  Check,
  ChevronDown,
  Crown,
  Flame,
  LocateFixed,
  LockKeyhole,
  MapPin,
  Menu,
  Minus,
  Plus,
  Search,
  ShoppingBag,
  SlidersHorizontal,
  Sparkles,
  X,
} from 'lucide-react'
import { categories, products, type Category, type Product } from './data'
import './styles.css'

type SortOption = 'nearest' | 'price-low' | 'price-high'
type Cart = Record<number, number>

const money = new Intl.NumberFormat('en-ZA', { style: 'currency', currency: 'ZAR' })

function App() {
  const [query, setQuery] = useState('')
  const [category, setCategory] = useState<Category | 'All'>('All')
  const [sort, setSort] = useState<SortOption>('nearest')
  const [subscriberStockOnly, setSubscriberStockOnly] = useState(false)
  const [filtersOpen, setFiltersOpen] = useState(false)
  const [cartOpen, setCartOpen] = useState(false)
  const [membershipOpen, setMembershipOpen] = useState(false)
  const [menuOpen, setMenuOpen] = useState(false)
  const [isMember, setIsMember] = useState(() => localStorage.getItem('biggar-member') === 'true')
  const [cart, setCart] = useState<Cart>({})
  const [toast, setToast] = useState('')

  const filteredProducts = useMemo(() => {
    const normalised = query.trim().toLowerCase()
    const result = products.filter((product) => {
      const matchesQuery =
        !normalised ||
        [product.name, product.cut, product.partner, product.suburb, product.category]
          .join(' ')
          .toLowerCase()
          .includes(normalised)
      const matchesCategory = category === 'All' || product.category === category
      const matchesStock = !subscriberStockOnly || product.subscriberOnly
      return matchesQuery && matchesCategory && matchesStock
    })

    return [...result].sort((a, b) => {
      if (sort === 'price-low') return a.price - b.price
      if (sort === 'price-high') return b.price - a.price
      return a.distance - b.distance
    })
  }, [category, query, sort, subscriberStockOnly])

  const cartItems = products.filter((product) => cart[product.id])
  const itemCount = Object.values(cart).reduce((sum, quantity) => sum + quantity, 0)
  const subtotal = cartItems.reduce((sum, product) => sum + product.price * cart[product.id], 0)
  const discount = isMember ? subtotal * 0.1 : 0

  const notify = (message: string) => {
    setToast(message)
    window.setTimeout(() => setToast(''), 2600)
  }

  const addToCart = (product: Product) => {
    if (product.subscriberOnly && !isMember) {
      setMembershipOpen(true)
      return
    }
    setCart((current) => ({
      ...current,
      [product.id]: Math.min((current[product.id] ?? 0) + 1, product.stock),
    }))
    notify(`${product.name} added to your bag`)
  }

  const updateQuantity = (product: Product, change: number) => {
    setCart((current) => {
      const nextQuantity = Math.max(0, Math.min((current[product.id] ?? 0) + change, product.stock))
      const next = { ...current }
      if (nextQuantity === 0) delete next[product.id]
      else next[product.id] = nextQuantity
      return next
    })
  }

  const activateMembership = () => {
    localStorage.setItem('biggar-member', 'true')
    setIsMember(true)
    setMembershipOpen(false)
    notify('Welcome to the Inner Circle — your 10% saving is active')
  }

  return (
    <div className="app">
      <div className="topbar">
        <span>Free collection from every partner</span>
        <button onClick={() => setMembershipOpen(true)}>
          <Crown size={14} /> {isMember ? 'Inner Circle active' : 'Members save 10%'}
        </button>
      </div>

      <header className="nav">
        <a className="brand" href="#" aria-label="Biggar Braai home">
          <span className="brand-mark"><Flame size={23} fill="currentColor" /></span>
          <span>BIGGAR<span>BRAAI</span></span>
        </a>
        <nav className={menuOpen ? 'nav-links open' : 'nav-links'} aria-label="Main navigation">
          <a className="active" href="#shop" onClick={() => setMenuOpen(false)}>Shop</a>
          <a href="#partners" onClick={() => setMenuOpen(false)}>Our partners</a>
          <button onClick={() => { setMembershipOpen(true); setMenuOpen(false) }}>Membership</button>
        </nav>
        <div className="nav-actions">
          <button className="location-button" aria-label="Change shopping location">
            <MapPin size={17} />
            <span>Stellenbosch</span>
            <ChevronDown size={15} />
          </button>
          <button className="icon-button bag-button" onClick={() => setCartOpen(true)} aria-label={`Shopping bag with ${itemCount} items`}>
            <ShoppingBag size={20} />
            {itemCount > 0 && <span>{itemCount}</span>}
          </button>
          <button className="icon-button menu-button" onClick={() => setMenuOpen(!menuOpen)} aria-label="Open menu">
            {menuOpen ? <X size={21} /> : <Menu size={21} />}
          </button>
        </div>
      </header>

      <main>
        <section className="hero" id="shop">
          <div className="hero-noise" />
          <div className="hero-copy">
            <div className="eyebrow"><span /> Local stock. Legendary braais.</div>
            <h1>Good meat.<br /><em>Closer than you think.</em></h1>
            <p>Find quality braai stock from trusted independent partners near you. Reserve online, collect fresh.</p>
            <div className="search-box">
              <Search size={21} />
              <input
                value={query}
                onChange={(event) => setQuery(event.target.value)}
                placeholder="What are you looking for?"
                aria-label="Search stock, products, or partners"
              />
              <button onClick={() => document.querySelector('#products')?.scrollIntoView({ behavior: 'smooth' })}>Find stock</button>
            </div>
            <div className="search-hints">
              <span>Popular:</span>
              {['Boerewors', 'Lamb chops', 'Braai packs'].map((hint) => (
                <button key={hint} onClick={() => setQuery(hint)}>{hint}</button>
              ))}
            </div>
          </div>
          <div className="hero-art" aria-hidden="true">
            <div className="sun" />
            <div className="hero-image" />
            <div className="availability-card">
              <span><LocateFixed size={19} /></span>
              <div><strong>8 products nearby</strong><small>Within 5 km of you</small></div>
            </div>
          </div>
        </section>

        <section className="category-strip" aria-label="Product categories">
          <button className={category === 'All' ? 'selected' : ''} onClick={() => setCategory('All')}>All stock</button>
          {categories.map((item) => (
            <button className={category === item ? 'selected' : ''} onClick={() => setCategory(item)} key={item}>{item}</button>
          ))}
        </section>

        <section className="catalog" id="products">
          <div className="catalog-heading">
            <div>
              <span className="section-kicker">AVAILABLE NEAR YOU</span>
              <h2>Stock worth firing up for</h2>
              <p>{filteredProducts.length} items from trusted partners around Stellenbosch</p>
            </div>
            <div className="catalog-controls">
              <button className={subscriberStockOnly ? 'filter-active' : ''} onClick={() => setFiltersOpen(!filtersOpen)}>
                <SlidersHorizontal size={17} /> Filters
                {subscriberStockOnly && <span className="filter-count">1</span>}
              </button>
              <label>
                <span>Sort:</span>
                <select value={sort} onChange={(event) => setSort(event.target.value as SortOption)}>
                  <option value="nearest">Nearest first</option>
                  <option value="price-low">Lowest price</option>
                  <option value="price-high">Highest price</option>
                </select>
              </label>
              {filtersOpen && (
                <div className="filter-popover">
                  <strong>Stock access</strong>
                  <label>
                    <input type="checkbox" checked={subscriberStockOnly} onChange={(event) => setSubscriberStockOnly(event.target.checked)} />
                    <span><Crown size={16} /> Inner Circle stock only</span>
                  </label>
                  <small>Show limited stock reserved for subscribers.</small>
                </div>
              )}
            </div>
          </div>

          {filteredProducts.length ? (
            <div className="product-grid">
              {filteredProducts.map((product) => (
                <article className="product-card" key={product.id}>
                  <div className="product-image-wrap">
                    <img src={product.image} alt="" className="product-image" />
                    <span className={`stock-pill ${product.stock <= 4 ? 'low-stock' : ''}`}>
                      {product.stock <= 4 ? `Only ${product.stock} left` : 'In stock'}
                    </span>
                    {product.subscriberOnly && (
                      <span className="member-pill"><Crown size={13} /> Inner Circle</span>
                    )}
                  </div>
                  <div className="product-body">
                    <span className="product-category">{product.category}</span>
                    <h3>{product.name}</h3>
                    <p className="cut">{product.cut}</p>
                    <div className="partner-row">
                      <MapPin size={16} />
                      <div>
                        <strong>{product.partner}</strong>
                        <span>{product.suburb} · {product.distance} km</span>
                      </div>
                      <a
                        href={`https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(`${product.partner}, ${product.suburb}`)}`}
                        target="_blank"
                        rel="noreferrer"
                        aria-label={`View ${product.partner} on map`}
                      >
                        View map
                      </a>
                    </div>
                    <div className="product-footer">
                      <div className="price">
                        {isMember && <small>{money.format(product.price)}</small>}
                        <strong>{money.format(isMember ? product.price * 0.9 : product.price)}</strong>
                        <span>/{product.unit}</span>
                      </div>
                      <button
                        className={product.subscriberOnly && !isMember ? 'locked-add' : ''}
                        onClick={() => addToCart(product)}
                        aria-label={product.subscriberOnly && !isMember ? `Unlock ${product.name}` : `Add ${product.name} to bag`}
                      >
                        {product.subscriberOnly && !isMember ? <LockKeyhole size={17} /> : <Plus size={19} />}
                        <span>{product.subscriberOnly && !isMember ? 'Unlock' : 'Add'}</span>
                      </button>
                    </div>
                  </div>
                </article>
              ))}
            </div>
          ) : (
            <div className="empty-state">
              <Search size={30} />
              <h3>No matching stock nearby</h3>
              <p>Try another search or clear your filters.</p>
              <button onClick={() => { setQuery(''); setCategory('All'); setSubscriberStockOnly(false) }}>Clear filters</button>
            </div>
          )}
        </section>

        <section className="membership-banner" id="membership">
          <div className="membership-icon"><Crown size={32} /></div>
          <div>
            <span>THE INNER CIRCLE</span>
            <h2>Your braai deserves first pick.</h2>
            <p>Save 10% on every order and get access to limited cuts reserved for members.</p>
          </div>
          <ul>
            <li><Check size={16} /> 10% off every item</li>
            <li><Check size={16} /> Restricted small-batch stock</li>
            <li><Check size={16} /> Cancel anytime</li>
          </ul>
          <button onClick={() => setMembershipOpen(true)}>{isMember ? 'View membership' : 'Join the Inner Circle'} <span>→</span></button>
        </section>

        <section className="partners" id="partners">
          <span className="section-kicker">OUR PARTNER NETWORK</span>
          <h2>Independent butchers. One simple shop.</h2>
          <p>Every item shows exactly who has it, how much is left and how far you’ll travel to collect it.</p>
          <div className="partner-logos">
            {['KAROO CRAFT', 'WINELANDS MEAT CO.', 'THE BLOCK', 'FARMHOUSE', 'OAK & EMBER'].map((partner) => <span key={partner}>{partner}</span>)}
          </div>
        </section>
      </main>

      <footer>
        <a className="brand footer-brand" href="#"><span className="brand-mark"><Flame size={20} fill="currentColor" /></span><span>BIGGAR<span>BRAAI</span></span></a>
        <p>Better stock. Better braais. Better local business.</p>
        <span>© 2026 Biggar Braai</span>
      </footer>

      {membershipOpen && (
        <div className="modal-backdrop" role="presentation" onMouseDown={() => setMembershipOpen(false)}>
          <div className="membership-modal" role="dialog" aria-modal="true" aria-labelledby="membership-title" onMouseDown={(event) => event.stopPropagation()}>
            <button className="modal-close" onClick={() => setMembershipOpen(false)} aria-label="Close membership"><X size={20} /></button>
            <div className="modal-crown"><Crown size={28} /></div>
            <span>BIGGAR BRAAI INNER CIRCLE</span>
            <h2 id="membership-title">{isMember ? 'You’re in the Inner Circle.' : 'First pick. Better price.'}</h2>
            <p>{isMember ? 'Your subscriber price and restricted stock access are active.' : 'Join the people who take their braai seriously.'}</p>
            <div className="modal-price"><strong>R99</strong><span>/ month</span></div>
            <ul>
              <li><Check size={18} /><span><strong>10% off every order</strong><small>Your saving is applied automatically.</small></span></li>
              <li><Check size={18} /><span><strong>Access restricted stock</strong><small>Limited cuts before they sell out.</small></span></li>
              <li><Check size={18} /><span><strong>No long-term commitment</strong><small>Pause or cancel your subscription anytime.</small></span></li>
            </ul>
            {!isMember && <button className="join-button" onClick={activateMembership}>Start my membership <span>→</span></button>}
            <small className="billing-note">{isMember ? 'Membership status: active' : 'Recurring monthly. Cancel anytime.'}</small>
          </div>
        </div>
      )}

      <aside className={`cart-drawer ${cartOpen ? 'open' : ''}`} aria-hidden={!cartOpen}>
        <div className="drawer-heading">
          <div><span>YOUR ORDER</span><h2>Shopping bag</h2></div>
          <button onClick={() => setCartOpen(false)} aria-label="Close shopping bag"><X size={21} /></button>
        </div>
        {!cartItems.length ? (
          <div className="cart-empty">
            <span><ShoppingBag size={27} /></span>
            <h3>Your bag is waiting</h3>
            <p>Find something worth putting on the fire.</p>
            <button onClick={() => setCartOpen(false)}>Browse stock</button>
          </div>
        ) : (
          <>
            <div className="cart-items">
              {cartItems.map((product) => (
                <div className="cart-item" key={product.id}>
                  <img src={product.image} alt="" />
                  <div>
                    <strong>{product.name}</strong>
                    <small>{product.partner}</small>
                    <span>{money.format(isMember ? product.price * 0.9 : product.price)}</span>
                  </div>
                  <div className="quantity">
                    <button onClick={() => updateQuantity(product, -1)} aria-label="Decrease quantity"><Minus size={14} /></button>
                    <span>{cart[product.id]}</span>
                    <button onClick={() => updateQuantity(product, 1)} aria-label="Increase quantity"><Plus size={14} /></button>
                  </div>
                </div>
              ))}
            </div>
            <div className="cart-summary">
              {!isMember && <button className="cart-saving" onClick={() => setMembershipOpen(true)}><Sparkles size={16} /> Join and save {money.format(subtotal * 0.1)} on this order</button>}
              <div><span>Subtotal</span><span>{money.format(subtotal)}</span></div>
              {isMember && <div className="discount"><span>Inner Circle saving</span><span>−{money.format(discount)}</span></div>}
              <div className="total"><strong>Total</strong><strong>{money.format(subtotal - discount)}</strong></div>
              <button className="checkout" onClick={() => notify('Checkout will connect to your payment provider')}>Reserve for collection <span>→</span></button>
              <small>Collection details confirmed after payment</small>
            </div>
          </>
        )}
      </aside>
      {cartOpen && <button className="drawer-backdrop" onClick={() => setCartOpen(false)} aria-label="Close shopping bag" />}
      {toast && <div className="toast" role="status"><Check size={17} /> {toast}</div>}
    </div>
  )
}

export default App
