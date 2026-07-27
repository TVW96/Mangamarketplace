\set ON_ERROR_STOP on

begin;

do $$
declare
  seller_id uuid;
  buyer_id uuid;
  trader_id uuid;
  product_one_id uuid;
  product_two_id uuid;
  product_three_id uuid;
  trade_product_id uuid;
  single_listing_id uuid;
  collection_listing_id uuid;
  trade_offer_id uuid;
  created_transaction_id uuid;
  active_count integer;
  observed_status listing_status;
  observed_owner uuid;
begin
  insert into app_users (username, email)
  values ('seller', 'seller@example.test')
  returning id into seller_id;

  insert into app_users (username, email)
  values ('buyer', 'buyer@example.test')
  returning id into buyer_id;

  insert into app_users (username, email)
  values ('trader', 'trader@example.test')
  returning id into trader_id;

  insert into products (
    owner_id, title, volume_number, condition
  )
  values (seller_id, 'Night Circuit', 1, 'like_new')
  returning id into product_one_id;

  insert into products (
    owner_id, title, volume_number, condition
  )
  values (seller_id, 'Night Circuit', 2, 'like_new')
  returning id into product_two_id;

  insert into products (
    owner_id, title, volume_number, condition
  )
  values (seller_id, 'Night Circuit', 3, 'like_new')
  returning id into product_three_id;

  insert into products (
    owner_id, title, volume_number, condition
  )
  values (trader_id, 'Ghost Radio Club', 7, 'very_good')
  returning id into trade_product_id;

  insert into listings (
    seller_id, kind, mode, title, price
  )
  values (seller_id, 'single', 'both', 'Night Circuit 01', 28)
  returning id into single_listing_id;

  insert into listings (
    seller_id, kind, mode, title, price
  )
  values (
    seller_id,
    'collection',
    'both',
    'Night Circuit 01–03',
    72
  )
  returning id into collection_listing_id;

  insert into listing_products (listing_id, product_id)
  values
    (single_listing_id, product_one_id),
    (collection_listing_id, product_one_id),
    (collection_listing_id, product_two_id),
    (collection_listing_id, product_three_id);

  perform activate_listing(single_listing_id, seller_id);
  perform activate_listing(collection_listing_id, seller_id);

  created_transaction_id := finalize_sale(
    single_listing_id,
    buyer_id,
    28,
    'USD',
    'test'
  );

  if created_transaction_id is null then
    raise exception 'Sale transaction was not created';
  end if;

  select owner_id into observed_owner
  from products
  where id = product_one_id;

  if observed_owner <> buyer_id then
    raise exception 'Sold product ownership did not transfer';
  end if;

  select status into observed_status
  from listings
  where id = single_listing_id;

  if observed_status <> 'closed' then
    raise exception 'Sold single listing did not close';
  end if;

  select status into observed_status
  from listings
  where id = collection_listing_id;

  select count(*) into active_count
  from listing_products
  where listing_id = collection_listing_id
    and removed_at is null;

  if observed_status <> 'active' or active_count <> 2 then
    raise exception 'Collection did not stay active with two remaining products';
  end if;

  insert into trade_offers (
    target_listing_id,
    proposer_id,
    recipient_id,
    cash_adjustment
  )
  values (
    collection_listing_id,
    trader_id,
    seller_id,
    5
  )
  returning id into trade_offer_id;

  insert into trade_offer_products (trade_offer_id, product_id, side)
  values
    (trade_offer_id, trade_product_id, 'proposer'),
    (trade_offer_id, product_two_id, 'recipient');

  created_transaction_id := accept_trade_offer(trade_offer_id, seller_id);

  if created_transaction_id is null then
    raise exception 'Trade transaction was not created';
  end if;

  select owner_id into observed_owner
  from products
  where id = product_two_id;

  if observed_owner <> trader_id then
    raise exception 'Recipient product ownership did not transfer';
  end if;

  select owner_id into observed_owner
  from products
  where id = trade_product_id;

  if observed_owner <> seller_id then
    raise exception 'Proposer product ownership did not transfer';
  end if;

  select status into observed_status
  from listings
  where id = collection_listing_id;

  if observed_status <> 'closed' then
    raise exception 'Collection did not close after falling below two products';
  end if;

  raise notice 'Marketplace sale and trade smoke test passed';
end;
$$;

rollback;
