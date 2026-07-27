-- Manga Marketplace core schema
-- PostgreSQL 15+
--
-- Design rule: one products row represents one physical copy.
-- That copy may be attached to several active listings through
-- listing_products, but ownership can only change once per transaction.

begin;

create extension if not exists pgcrypto;

create type product_availability as enum (
  'unlisted',
  'available',
  'reserved',
  'removed'
);

create type transfer_kind as enum (
  'sale',
  'trade'
);

create type listing_kind as enum (
  'single',
  'collection'
);

create type listing_mode as enum (
  'sale',
  'trade',
  'both'
);

create type listing_status as enum (
  'draft',
  'active',
  'reserved',
  'closed',
  'cancelled'
);

create type transaction_kind as enum (
  'sale',
  'trade'
);

create type transaction_status as enum (
  'pending',
  'completed',
  'cancelled',
  'disputed'
);

create type trade_offer_status as enum (
  'pending',
  'accepted',
  'rejected',
  'cancelled',
  'expired'
);

create type trade_offer_side as enum (
  'proposer',
  'recipient'
);

create table app_users (
  id uuid primary key default gen_random_uuid(),
  username text not null unique,
  email text not null unique,
  display_name text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table products (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references app_users (id),
  title text not null,
  series text,
  volume_number integer check (volume_number is null or volume_number > 0),
  product_type text,
  author text,
  publisher text,
  isbn text,
  description text,
  condition text not null,
  availability product_availability not null default 'unlisted',
  last_transfer transfer_kind,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index products_owner_idx on products (owner_id);
create index products_isbn_idx on products (isbn) where isbn is not null;

create table product_images (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references products (id) on delete cascade,
  storage_bucket text not null,
  storage_path text not null,
  alt_text text,
  display_order integer not null default 0,
  is_primary boolean not null default false,
  created_at timestamptz not null default now(),
  unique (storage_bucket, storage_path)
);

create unique index product_images_one_primary_idx
  on product_images (product_id)
  where is_primary;

create table listings (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid not null references app_users (id),
  kind listing_kind not null,
  mode listing_mode not null default 'sale',
  title text not null,
  description text,
  price numeric(12, 2),
  currency char(3) not null default 'USD',
  category text,
  status listing_status not null default 'draft',
  closed_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (price is null or price >= 0),
  check (mode = 'trade' or price is not null)
);

create index listings_seller_status_idx on listings (seller_id, status);

create table listing_products (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references listings (id) on delete cascade,
  product_id uuid not null references products (id),
  quantity integer not null default 1 check (quantity = 1),
  added_at timestamptz not null default now(),
  removed_at timestamptz,
  removal_reason text,
  unique (listing_id, product_id),
  check (
    (removed_at is null and removal_reason is null)
    or removed_at is not null
  )
);

create index listing_products_product_active_idx
  on listing_products (product_id)
  where removed_at is null;

create index listing_products_listing_active_idx
  on listing_products (listing_id)
  where removed_at is null;

create table listing_images (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references listings (id) on delete cascade,
  storage_bucket text not null,
  storage_path text not null,
  alt_text text,
  display_order integer not null default 0,
  is_primary boolean not null default false,
  created_at timestamptz not null default now(),
  unique (storage_bucket, storage_path)
);

create unique index listing_images_one_primary_idx
  on listing_images (listing_id)
  where is_primary;

create table marketplace_transactions (
  id uuid primary key default gen_random_uuid(),
  kind transaction_kind not null,
  listing_id uuid references listings (id),
  buyer_id uuid references app_users (id),
  seller_id uuid references app_users (id),
  amount numeric(12, 2),
  currency char(3) not null default 'USD',
  status transaction_status not null default 'pending',
  payment_method text,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  check (amount is null or amount >= 0),
  check (
    (kind = 'sale' and buyer_id is not null and seller_id is not null)
    or kind = 'trade'
  )
);

create table transaction_products (
  id uuid primary key default gen_random_uuid(),
  transaction_id uuid not null
    references marketplace_transactions (id) on delete cascade,
  product_id uuid not null references products (id),
  from_user_id uuid not null references app_users (id),
  to_user_id uuid not null references app_users (id),
  condition_snapshot text not null,
  unique (transaction_id, product_id),
  check (from_user_id <> to_user_id)
);

create table trade_offers (
  id uuid primary key default gen_random_uuid(),
  target_listing_id uuid not null references listings (id),
  proposer_id uuid not null references app_users (id),
  recipient_id uuid not null references app_users (id),
  cash_adjustment numeric(12, 2) not null default 0,
  currency char(3) not null default 'USD',
  message text,
  status trade_offer_status not null default 'pending',
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (proposer_id <> recipient_id)
);

create index trade_offers_recipient_status_idx
  on trade_offers (recipient_id, status);

create table trade_offer_products (
  id uuid primary key default gen_random_uuid(),
  trade_offer_id uuid not null references trade_offers (id) on delete cascade,
  product_id uuid not null references products (id),
  side trade_offer_side not null,
  unique (trade_offer_id, product_id)
);

create index trade_offer_products_product_idx
  on trade_offer_products (product_id);

create table app_reviews (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references app_users (id),
  rating integer not null check (rating between 1 and 5),
  title text,
  review text,
  app_version text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table seller_reviews (
  id uuid primary key default gen_random_uuid(),
  reviewer_id uuid not null references app_users (id),
  seller_id uuid not null references app_users (id),
  transaction_id uuid not null unique
    references marketplace_transactions (id),
  rating integer not null check (rating between 1 and 5),
  title text,
  review text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (reviewer_id <> seller_id)
);

-- Prevent a seller from attaching another user's physical copy to a listing.
create or replace function validate_listing_product_owner()
returns trigger
language plpgsql
as $$
declare
  listing_seller uuid;
  product_owner uuid;
begin
  select seller_id into listing_seller
  from listings
  where id = new.listing_id;

  select owner_id into product_owner
  from products
  where id = new.product_id;

  if listing_seller is null or product_owner is null then
    raise exception 'Listing and product must exist';
  end if;

  if listing_seller <> product_owner then
    raise exception 'Product owner must match listing seller';
  end if;

  return new;
end;
$$;

create trigger listing_product_owner_guard
before insert or update of listing_id, product_id
on listing_products
for each row
execute function validate_listing_product_owner();

-- Active single listings require exactly one live product. Active collections
-- require at least two. When a membership disappears, close any listing that
-- no longer satisfies that shape.
create or replace function close_listing_below_minimum()
returns trigger
language plpgsql
as $$
declare
  affected_listing_id uuid;
  affected_kind listing_kind;
  active_product_count integer;
begin
  affected_listing_id := coalesce(new.listing_id, old.listing_id);

  select kind into affected_kind
  from listings
  where id = affected_listing_id;

  select count(*) into active_product_count
  from listing_products
  where listing_id = affected_listing_id
    and removed_at is null;

  update listings
  set
    status = 'closed',
    closed_reason = case
      when affected_kind = 'single' then 'single_product_unavailable'
      else 'collection_below_minimum'
    end,
    updated_at = now()
  where id = affected_listing_id
    and status in ('active', 'reserved')
    and (
      (affected_kind = 'single' and active_product_count < 1)
      or (affected_kind = 'collection' and active_product_count < 2)
    );

  return null;
end;
$$;

create trigger listing_shape_after_product_change
after delete or update of removed_at
on listing_products
for each row
execute function close_listing_below_minimum();

-- Any ownership change (sale or trade) or explicit removal retires the copy
-- from every listing that references it. Historical join rows remain intact.
create or replace function retire_product_from_listings()
returns trigger
language plpgsql
as $$
begin
  if old.owner_id is distinct from new.owner_id
     or (
       old.availability is distinct from new.availability
       and new.availability = 'removed'
     ) then
    update listing_products
    set
      removed_at = now(),
      removal_reason = case
        when new.last_transfer = 'sale' then 'sold'
        when new.last_transfer = 'trade' then 'traded'
        else 'product_removed'
      end
    where product_id = new.id
      and removed_at is null;
  end if;

  return new;
end;
$$;

create trigger product_listing_retirement
after update of owner_id, availability
on products
for each row
execute function retire_product_from_listings();

-- Applications should call this function instead of directly publishing a
-- listing. It verifies ownership, availability, and the one-vs-many rule.
create or replace function activate_listing(
  requested_listing_id uuid,
  acting_seller_id uuid
)
returns listings
language plpgsql
as $$
declare
  selected_listing listings;
  product_count integer;
  invalid_product_count integer;
begin
  select * into selected_listing
  from listings
  where id = requested_listing_id
  for update;

  if not found or selected_listing.seller_id <> acting_seller_id then
    raise exception 'Listing not found for seller';
  end if;

  select
    count(*),
    count(*) filter (
      where p.owner_id <> acting_seller_id
         or p.availability in ('reserved', 'removed')
    )
  into product_count, invalid_product_count
  from listing_products lp
  join products p on p.id = lp.product_id
  where lp.listing_id = requested_listing_id
    and lp.removed_at is null;

  if invalid_product_count > 0 then
    raise exception 'Every product must be owned and available to the seller';
  end if;

  if selected_listing.kind = 'single' and product_count <> 1 then
    raise exception 'A single listing must contain exactly one product';
  end if;

  if selected_listing.kind = 'collection' and product_count < 2 then
    raise exception 'A collection listing must contain at least two products';
  end if;

  update products p
  set availability = 'available', updated_at = now()
  from listing_products lp
  where lp.listing_id = requested_listing_id
    and lp.product_id = p.id
    and lp.removed_at is null;

  update listings
  set
    status = 'active',
    closed_reason = null,
    updated_at = now()
  where id = requested_listing_id
  returning * into selected_listing;

  return selected_listing;
end;
$$;

-- Finalize a sale while locking the listing and every physical copy. Updating
-- ownership fires product_listing_retirement, which removes each sold product
-- from all other single/collection listings in the same transaction.
create or replace function finalize_sale(
  requested_listing_id uuid,
  purchasing_user_id uuid,
  paid_amount numeric,
  paid_currency char(3) default 'USD',
  used_payment_method text default null
)
returns uuid
language plpgsql
as $$
declare
  selected_listing listings;
  sold_product_ids uuid[];
  expected_product_count integer;
  created_transaction_id uuid;
begin
  select * into selected_listing
  from listings
  where id = requested_listing_id
  for update;

  if not found
     or selected_listing.status <> 'active'
     or selected_listing.mode not in ('sale', 'both') then
    raise exception 'Listing is not available for sale';
  end if;

  if selected_listing.seller_id = purchasing_user_id then
    raise exception 'Seller cannot buy their own listing';
  end if;

  select array_agg(p.id order by p.id)
  into sold_product_ids
  from products p
  join listing_products lp on lp.product_id = p.id
  where lp.listing_id = requested_listing_id
    and lp.removed_at is null
    and p.owner_id = selected_listing.seller_id
    and p.availability = 'available';

  select count(*) into expected_product_count
  from listing_products
  where listing_id = requested_listing_id
    and removed_at is null;

  if coalesce(cardinality(sold_product_ids), 0) = 0
     or cardinality(sold_product_ids) <> expected_product_count then
    raise exception 'One or more listing products are no longer available';
  end if;

  perform 1
  from products
  where id = any(sold_product_ids)
  order by id
  for update;

  insert into marketplace_transactions (
    kind,
    listing_id,
    buyer_id,
    seller_id,
    amount,
    currency,
    status,
    payment_method,
    completed_at
  )
  values (
    'sale',
    requested_listing_id,
    purchasing_user_id,
    selected_listing.seller_id,
    paid_amount,
    paid_currency,
    'completed',
    used_payment_method,
    now()
  )
  returning id into created_transaction_id;

  insert into transaction_products (
    transaction_id,
    product_id,
    from_user_id,
    to_user_id,
    condition_snapshot
  )
  select
    created_transaction_id,
    id,
    owner_id,
    purchasing_user_id,
    condition
  from products
  where id = any(sold_product_ids);

  update products
  set
    owner_id = purchasing_user_id,
    availability = 'unlisted',
    last_transfer = 'sale',
    updated_at = now()
  where id = any(sold_product_ids);

  return created_transaction_id;
end;
$$;

-- Accept a two-sided trade atomically. All copies are locked, ownership is
-- swapped, related listings are cleaned up, and competing offers expire.
create or replace function accept_trade_offer(
  requested_offer_id uuid,
  acting_recipient_id uuid
)
returns uuid
language plpgsql
as $$
declare
  selected_offer trade_offers;
  proposer_product_ids uuid[];
  recipient_product_ids uuid[];
  all_product_ids uuid[];
  invalid_product_count integer;
  created_transaction_id uuid;
begin
  select * into selected_offer
  from trade_offers
  where id = requested_offer_id
  for update;

  if not found
     or selected_offer.recipient_id <> acting_recipient_id
     or selected_offer.status <> 'pending'
     or (
       selected_offer.expires_at is not null
       and selected_offer.expires_at <= now()
     ) then
    raise exception 'Trade offer is not available to accept';
  end if;

  select
    array_agg(product_id order by product_id)
      filter (where side = 'proposer'),
    array_agg(product_id order by product_id)
      filter (where side = 'recipient'),
    array_agg(product_id order by product_id)
  into proposer_product_ids, recipient_product_ids, all_product_ids
  from trade_offer_products
  where trade_offer_id = requested_offer_id;

  if coalesce(cardinality(proposer_product_ids), 0) = 0
     or coalesce(cardinality(recipient_product_ids), 0) = 0 then
    raise exception 'A trade must contain products from both sides';
  end if;

  perform 1
  from products
  where id = any(all_product_ids)
  order by id
  for update;

  select count(*) into invalid_product_count
  from trade_offer_products top
  join products p on p.id = top.product_id
  where top.trade_offer_id = requested_offer_id
    and (
      p.availability in ('reserved', 'removed')
      or (
        top.side = 'proposer'
        and p.owner_id <> selected_offer.proposer_id
      )
      or (
        top.side = 'recipient'
        and p.owner_id <> selected_offer.recipient_id
      )
      or (
        top.side = 'recipient'
        and not exists (
          select 1
          from listing_products target_product
          where target_product.listing_id = selected_offer.target_listing_id
            and target_product.product_id = top.product_id
            and target_product.removed_at is null
        )
      )
    );

  if invalid_product_count > 0 then
    raise exception 'One or more trade products are no longer available';
  end if;

  insert into marketplace_transactions (
    kind,
    listing_id,
    amount,
    currency,
    status,
    completed_at
  )
  values (
    'trade',
    selected_offer.target_listing_id,
    abs(selected_offer.cash_adjustment),
    selected_offer.currency,
    'completed',
    now()
  )
  returning id into created_transaction_id;

  insert into transaction_products (
    transaction_id,
    product_id,
    from_user_id,
    to_user_id,
    condition_snapshot
  )
  select
    created_transaction_id,
    p.id,
    p.owner_id,
    case top.side
      when 'proposer' then selected_offer.recipient_id
      else selected_offer.proposer_id
    end,
    p.condition
  from trade_offer_products top
  join products p on p.id = top.product_id
  where top.trade_offer_id = requested_offer_id;

  update products
  set
    owner_id = selected_offer.recipient_id,
    availability = 'unlisted',
    last_transfer = 'trade',
    updated_at = now()
  where id = any(proposer_product_ids);

  update products
  set
    owner_id = selected_offer.proposer_id,
    availability = 'unlisted',
    last_transfer = 'trade',
    updated_at = now()
  where id = any(recipient_product_ids);

  update trade_offers
  set status = 'accepted', updated_at = now()
  where id = requested_offer_id;

  update trade_offers competing_offer
  set status = 'expired', updated_at = now()
  where competing_offer.id <> requested_offer_id
    and competing_offer.status = 'pending'
    and exists (
      select 1
      from trade_offer_products competing_product
      where competing_product.trade_offer_id = competing_offer.id
        and competing_product.product_id = any(all_product_ids)
    );

  return created_transaction_id;
end;
$$;

comment on table products is
  'One row per physical copy. Bibliographic duplicates are separate products.';
comment on table listing_products is
  'Many-to-many listing membership. removed_at preserves listing history.';
comment on function finalize_sale is
  'Atomically transfers ownership and retires sold products from every listing.';
comment on function accept_trade_offer is
  'Atomically swaps ownership for both sides of an accepted trade.';

commit;
