import {
  useEffect,
  useState,
  type CSSProperties,
  type FormEvent,
  type ReactNode,
} from 'react'
import './App.css'

type Theme = 'light' | 'dark'
type CoverTone = 'signal' | 'violet' | 'cyan' | 'mono' | 'amber'

type Listing = {
  id: string
  eyebrow: string
  title: string
  creator: string
  price: string
  detail: string
  tone: CoverTone
  badge?: string
  isCollection?: boolean
}

const listings: Listing[] = [
  {
    id: 'listing-101',
    eyebrow: 'Seinen · First print',
    title: 'Signal / Noise 01',
    creator: 'Aki Nomura',
    price: '$24',
    detail: 'Like new',
    tone: 'signal',
    badge: 'Hot',
  },
  {
    id: 'listing-102',
    eyebrow: 'Collection · 4 volumes',
    title: 'Neon Pilgrim Set',
    creator: 'Kei Matsuda',
    price: '$72',
    detail: 'Very good',
    tone: 'violet',
    badge: 'Bundle',
    isCollection: true,
  },
  {
    id: 'listing-103',
    eyebrow: 'Josei · One-shot',
    title: 'Blue Hour Taxi',
    creator: 'Sora Ishii',
    price: '$18',
    detail: 'New',
    tone: 'cyan',
    badge: 'Trade open',
  },
  {
    id: 'listing-104',
    eyebrow: 'Art book · 2022',
    title: 'Soft Machine',
    creator: 'Rin Kuroda',
    price: '$36',
    detail: 'Good',
    tone: 'mono',
  },
]

const marketRows = [
  ['01', 'Ghost Radio Club', 'First / 2025', '↑ 18%', 'up'],
  ['02', 'Antenna Garden', 'Complete / 7 vol.', '↑ 12%', 'up'],
  ['03', 'Paper Moons', 'Deluxe / 2023', '→ 04%', 'steady'],
  ['04', 'Salt City Kids', 'Reprint / 2026', '↑ 09%', 'up'],
  ['05', 'Blue Hour Taxi', 'One-shot / 2024', 'New', 'new'],
]

function getInitialTheme(): Theme {
  const savedTheme = window.localStorage.getItem('manga-market-theme')

  if (savedTheme === 'light' || savedTheme === 'dark') {
    return savedTheme
  }

  return window.matchMedia('(prefers-color-scheme: dark)').matches
    ? 'dark'
    : 'light'
}

function Icon({
  children,
  size = 20,
}: {
  children: ReactNode
  size?: number
}) {
  return (
    <svg
      aria-hidden="true"
      className="icon"
      fill="none"
      height={size}
      viewBox="0 0 24 24"
      width={size}
    >
      {children}
    </svg>
  )
}

function SearchIcon() {
  return (
    <Icon>
      <circle cx="11" cy="11" r="6.5" />
      <path d="m16 16 4 4" />
    </Icon>
  )
}

function SunIcon() {
  return (
    <Icon>
      <circle cx="12" cy="12" r="3.5" />
      <path d="M12 2v2M12 20v2M4.93 4.93l1.42 1.42M17.65 17.65l1.42 1.42M2 12h2M20 12h2M4.93 19.07l1.42-1.42M17.65 6.35l1.42-1.42" />
    </Icon>
  )
}

function MoonIcon() {
  return (
    <Icon>
      <path d="M20.2 15.4A8.4 8.4 0 0 1 8.6 3.8 8.4 8.4 0 1 0 20.2 15.4Z" />
    </Icon>
  )
}

function HeartIcon() {
  return (
    <Icon size={18}>
      <path d="M20.8 4.7a5.5 5.5 0 0 0-7.8 0L12 5.8l-1.1-1.1a5.5 5.5 0 0 0-7.8 7.8l1.1 1.1L12 21l7.8-7.4 1.1-1.1a5.5 5.5 0 0 0-.1-7.8Z" />
    </Icon>
  )
}

function ArrowIcon() {
  return (
    <Icon size={18}>
      <path d="M5 12h14M14 7l5 5-5 5" />
    </Icon>
  )
}

function CoverArt({
  tone,
  title,
  collection = false,
}: {
  tone: CoverTone
  title: string
  collection?: boolean
}) {
  return (
    <div
      aria-label={`${title} cover art${collection ? ', shown as a collection' : ''}`}
      className={`cover-art cover-art--${tone}${collection ? ' cover-art--collection' : ''}`}
      role="img"
    >
      {collection && <span className="cover-art__volume cover-art__volume--back" />}
      {collection && <span className="cover-art__volume cover-art__volume--mid" />}
      <span className="cover-art__grid" />
      <span className="cover-art__number">{collection ? '04' : '01'}</span>
      <span className="cover-art__jp" lang="ja">
        漫画市場
      </span>
      <strong className="cover-art__title">{title}</strong>
      <span className="cover-art__stamp">MM</span>
    </div>
  )
}

function ListingCard({
  listing,
  saved,
  onSave,
}: {
  listing: Listing
  saved: boolean
  onSave: () => void
}) {
  return (
    <article className="listing-card">
      <div className="listing-card__visual">
        <a aria-label={`View ${listing.title}`} href={`#${listing.id}`}>
          <CoverArt
            collection={listing.isCollection}
            title={listing.title}
            tone={listing.tone}
          />
        </a>
        {listing.badge && <span className="listing-card__badge">{listing.badge}</span>}
        <button
          aria-label={`${saved ? 'Remove' : 'Save'} ${listing.title}`}
          aria-pressed={saved}
          className="save-button"
          onClick={onSave}
          type="button"
        >
          <HeartIcon />
        </button>
      </div>
      <div className="listing-card__meta">
        <p className="eyebrow">{listing.eyebrow}</p>
        <p>{listing.price}</p>
      </div>
      <h3 id={listing.id}>
        <a href={`#${listing.id}`}>{listing.title}</a>
      </h3>
      <div className="listing-card__meta listing-card__meta--subtle">
        <p>{listing.creator}</p>
        <p>{listing.detail}</p>
      </div>
    </article>
  )
}

function App() {
  const [theme, setTheme] = useState<Theme>(getInitialTheme)
  const [savedListings, setSavedListings] = useState<string[]>([])

  useEffect(() => {
    document.documentElement.dataset.theme = theme
    document.documentElement.style.colorScheme = theme
    document
      .querySelector('meta[name="theme-color"]')
      ?.setAttribute('content', theme === 'dark' ? '#0b0f16' : '#f7f2e7')
    window.localStorage.setItem('manga-market-theme', theme)
  }, [theme])

  const toggleSavedListing = (listingId: string) => {
    setSavedListings((current) =>
      current.includes(listingId)
        ? current.filter((id) => id !== listingId)
        : [...current, listingId],
    )
  }

  const preventSubmit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
  }

  return (
    <>
      <a className="skip-link" href="#main-content">
        Skip to marketplace
      </a>

      <div className="issue-strip">
        <p>Issue 01 / Summer 2026</p>
        <p>Protected trades · Verified sellers</p>
        <p>Los Angeles · Tokyo · Worldwide</p>
      </div>

      <header className="site-header">
        <div className="masthead">
          <p className="masthead__note">
            Peer-to-peer manga
            <br />
            curated daily
          </p>
          <a aria-label="Manga Marketplace home" className="wordmark" href="#">
            <span>Manga</span>
            <strong>Marketplace</strong>
            <small lang="ja">漫画市場</small>
          </a>
          <div className="header-actions">
            <button
              aria-label={`Switch to ${theme === 'light' ? 'dark' : 'light'} mode`}
              className="icon-button"
              onClick={() => setTheme(theme === 'light' ? 'dark' : 'light')}
              type="button"
            >
              {theme === 'light' ? <MoonIcon /> : <SunIcon />}
            </button>
            <a href="#trade-desk">Account</a>
            <a href="#fresh-listings">
              Saved <span className="count-badge">{String(savedListings.length).padStart(2, '0')}</span>
            </a>
          </div>
        </div>

        <div className="navigation-row">
          <nav aria-label="Primary navigation">
            <a href="#fresh-listings">Browse</a>
            <a href="#sell">Sell</a>
            <a href="#trade-desk">Trade</a>
            <a href="#collections">Collections</a>
            <a href="#journal">Journal</a>
          </nav>
          <form aria-label="Marketplace search" className="search-form" onSubmit={preventSubmit} role="search">
            <label className="sr-only" htmlFor="market-search">
              Search titles, creators, and ISBNs
            </label>
            <input
              id="market-search"
              name="query"
              placeholder="Search titles, creators, ISBNs"
              type="search"
            />
            <button aria-label="Submit search" type="submit">
              <SearchIcon />
            </button>
          </form>
        </div>
      </header>

      <main id="main-content">
        <section aria-labelledby="feature-heading" className="feature">
          <div className="feature__intro">
            <div>
              <p className="section-index">
                <span>01</span> This week’s acquisition
              </p>
              <h1 id="feature-heading">
                Stories worth <em>keeping.</em> Shelves worth sharing.
              </h1>
              <p className="feature__dek">
                A collector-minded market for manga to buy, sell, bundle, and
                trade—with every physical volume tracked from listing to handoff.
              </p>
            </div>
            <a className="text-link" href="#fresh-listings">
              Browse the latest drop <ArrowIcon />
            </a>
          </div>

          <figure className="feature__art">
            <CoverArt title="Night Circuit" tone="signal" />
            <figcaption>
              <span>Cover study / Seller archive</span>
              <span>Item NC-026</span>
            </figcaption>
          </figure>

          <aside aria-label="Featured listing details" className="feature__details">
            <div>
              <p className="eyebrow eyebrow--accent">Editor’s acquisition</p>
              <h2>Night Circuit <span>Vol. 04</span></h2>
              <p className="byline">Mina Sorayama · English edition</p>
            </div>
            <p className="feature__description">
              A neon-noir courier story in a clean first printing. Includes the
              original obi strip and a numbered risograph bookplate.
            </p>
            <dl className="spec-list">
              <div>
                <dt>Format</dt>
                <dd>Softcover / 224p</dd>
              </div>
              <div>
                <dt>Condition</dt>
                <dd>Like new</dd>
              </div>
              <div>
                <dt>Seller</dt>
                <dd>PaperSatellite · 4.9</dd>
              </div>
              <div>
                <dt>Trade</dt>
                <dd>Open to offers</dd>
              </div>
            </dl>
            <div className="price-block">
              <p>Collector price</p>
              <strong>$28.00</strong>
            </div>
            <div className="feature__actions">
              <a className="button button--primary" href="#fresh-listings">
                Buy now
              </a>
              <a className="button button--secondary" href="#trade-desk">
                Propose trade
              </a>
            </div>
          </aside>
        </section>

        <section aria-labelledby="fresh-heading" className="section-shell" id="fresh-listings">
          <header className="section-heading">
            <div>
              <p className="section-index">
                <span>02</span> Fresh on the shelf
              </p>
              <h2 id="fresh-heading">New listings</h2>
            </div>
            <p>
              Single volumes and collector-built sets, selected for edition,
              condition, and a point of view.
            </p>
            <a className="text-link" href="#market-pulse">
              View complete market <ArrowIcon />
            </a>
          </header>

          <div className="listing-grid">
            {listings.map((listing) => (
              <ListingCard
                key={listing.id}
                listing={listing}
                onSave={() => toggleSavedListing(listing.id)}
                saved={savedListings.includes(listing.id)}
              />
            ))}
          </div>
        </section>

        <section aria-labelledby="collection-heading" className="collection-feature" id="collections">
          <div className="collection-feature__art">
            <span className="vertical-copy" lang="ja">完全版</span>
            <div className="collection-stack" aria-label="Seven volume manga collection" role="img">
              {Array.from({ length: 7 }, (_, index) => (
                <span key={index} style={{ '--volume': index } as CSSProperties}>
                  <b>{String(index + 1).padStart(2, '0')}</b>
                  <small>ANTENNA GARDEN</small>
                </span>
              ))}
            </div>
          </div>
          <article>
            <p className="section-index">
              <span>03</span> Complete-set desk
            </p>
            <h2 id="collection-heading">
              One story.
              <br />
              Seven volumes.
              <br />
              <em>One listing.</em>
            </h2>
            <p>
              Collection listings keep each physical book independently
              traceable. If a volume sells elsewhere, the set updates
              automatically—so buyers never chase a book that is already gone.
            </p>
            <dl className="collection-stats">
              <div>
                <dt>Volumes</dt>
                <dd>01–07</dd>
              </div>
              <div>
                <dt>Condition</dt>
                <dd>Very good</dd>
              </div>
              <div>
                <dt>Asking</dt>
                <dd>$96</dd>
              </div>
            </dl>
            <a className="text-link text-link--light" href="#sell">
              View collection <ArrowIcon />
            </a>
          </article>
        </section>

        <section aria-labelledby="trade-heading" className="section-shell trade-desk" id="trade-desk">
          <header>
            <p className="section-index">
              <span>04</span> Trade desk
            </p>
            <h2 id="trade-heading">Make the shelf move.</h2>
            <p>
              Offer books from your collection, request exact volumes, and add a
              cash adjustment when the values do not quite meet.
            </p>
          </header>

          <div className="trade-board">
            <article className="trade-side">
              <div className="trade-side__label">
                <span>Your offer</span>
                <small>2 items · $41 value</small>
              </div>
              <div className="mini-covers" aria-label="Two books offered for trade" role="img">
                <span className="mini-cover mini-cover--red">01</span>
                <span className="mini-cover mini-cover--cyan">03</span>
              </div>
              <strong>Signal / Noise 01 + Blue Hour Taxi</strong>
            </article>

            <div aria-hidden="true" className="trade-swap">
              <span>⇄</span>
              <small>Protected exchange</small>
            </div>

            <article className="trade-side">
              <div className="trade-side__label">
                <span>You request</span>
                <small>1 item · $46 value</small>
              </div>
              <div className="mini-covers" aria-label="One book requested in trade" role="img">
                <span className="mini-cover mini-cover--violet">07</span>
              </div>
              <strong>Ghost Radio Club 07</strong>
            </article>
          </div>

          <ol className="trade-steps">
            <li>
              <span>01</span>
              <div>
                <strong>Build an offer</strong>
                <p>Select only products you own and that are currently available.</p>
              </div>
            </li>
            <li>
              <span>02</span>
              <div>
                <strong>Agree on value</strong>
                <p>Add an optional cash difference, then both members confirm.</p>
              </div>
            </li>
            <li>
              <span>03</span>
              <div>
                <strong>Exchange safely</strong>
                <p>Items lock during the trade and every related listing updates.</p>
              </div>
            </li>
          </ol>
          <a className="button button--primary trade-desk__button" href="#sell">
            Start a trade
          </a>
        </section>

        <section aria-labelledby="market-heading" className="market-pulse" id="market-pulse">
          <header>
            <div>
              <p className="section-index">
                <span>05</span> Collector’s ledger
              </p>
              <h2 id="market-heading">What the market is watching.</h2>
            </div>
            <p>
              Movement across small editions, complete runs, and overlooked
              first volumes. Updated every Friday.
            </p>
          </header>

          <div className="table-wrap">
            <table>
              <caption className="sr-only">Manga collector market movement</caption>
              <thead>
                <tr>
                  <th scope="col">Rank</th>
                  <th scope="col">Title</th>
                  <th scope="col">Edition</th>
                  <th scope="col">Demand</th>
                </tr>
              </thead>
              <tbody>
                {marketRows.map(([rank, title, edition, demand, movement]) => (
                  <tr key={rank}>
                    <td>{rank}</td>
                    <th scope="row">{title}</th>
                    <td>{edition}</td>
                    <td className={`movement movement--${movement}`}>{demand}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </section>

        <section aria-labelledby="journal-heading" className="journal" id="journal">
          <figure>
            <div className="journal-art" aria-label="Abstract night view of a Tokyo book district" role="img">
              <span lang="ja">古書と漫画</span>
              <span>BOOKS</span>
              <span lang="ja">買取</span>
              <span>24:00</span>
            </div>
            <figcaption>Jinbōchō, Tokyo / 10:42 PM</figcaption>
          </figure>
          <article>
            <p className="section-index">
              <span>06</span> Field notes
            </p>
            <h2 id="journal-heading">After-hours in Tokyo’s book district</h2>
            <p className="journal__dek">
              The shutters come down, but the buying never really stops.
            </p>
            <p>
              Between used-book towers and tiny specialty shops, collectors trade
              tips with the urgency of breaking news. A missing dust jacket
              changes the price; a handwritten receipt can become provenance.
            </p>
            <a className="text-link" href="#newsletter">
              Read the full dispatch <ArrowIcon />
            </a>
          </article>
        </section>

        <section aria-labelledby="sell-heading" className="sell-banner" id="sell">
          <p className="eyebrow">Your shelf, your terms</p>
          <h2 id="sell-heading">List one. Bundle many. Trade anything.</h2>
          <p>
            Create a product once, then include it in individual and collection
            listings without losing track of the physical copy.
          </p>
          <a className="button button--paper" href="#newsletter">
            Create a listing
          </a>
        </section>

        <section aria-labelledby="newsletter-heading" className="newsletter" id="newsletter">
          <div>
            <p className="eyebrow">The Friday drop</p>
            <h2 id="newsletter-heading">
              One sharp edit.
              <span>No endless scroll.</span>
            </h2>
          </div>
          <form onSubmit={preventSubmit}>
            <label htmlFor="newsletter-email">
              New listings, trade matches, and collection alerts.
            </label>
            <div>
              <input
                autoComplete="email"
                id="newsletter-email"
                placeholder="Email address"
                required
                type="email"
              />
              <button className="button button--primary" type="submit">
                Join the list
              </button>
            </div>
          </form>
        </section>
      </main>

      <footer className="site-footer">
        <a aria-label="Manga Marketplace home" className="footer-wordmark" href="#">
          <span>Manga</span>
          <span>Marketplace</span>
          <small lang="ja">漫画市場</small>
        </a>
        <nav aria-label="Marketplace links">
          <p>Marketplace</p>
          <a href="#fresh-listings">New listings</a>
          <a href="#collections">Collections</a>
          <a href="#trade-desk">Trade desk</a>
        </nav>
        <nav aria-label="Seller links">
          <p>Sellers</p>
          <a href="#sell">Create a listing</a>
          <a href="#market-pulse">Price ledger</a>
          <a href="#newsletter">Condition guide</a>
        </nav>
        <div className="site-footer__legal">
          <p>© 2026 Manga Marketplace</p>
          <p>Prototype catalogue · All titles are fictional</p>
          <a href="#main-content">Back to top ↑</a>
        </div>
      </footer>
    </>
  )
}

export default App
