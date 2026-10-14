# Multi-family spaces

This fork keeps Sure's existing `users.family_id` as the user's home family
and adds `family_memberships` for additional spaces. A membership never moves
accounts, provider connections, transactions, or ownership records.

The active family is selected in the signed-in session and can be changed from
Settings > Families. API clients may send `X-Sure-Family-Id`; the server only
accepts a family where the authenticated user has a membership. An invalid or
non-member family returns `403` and never falls back to another user's data.

The migration backfills one membership from every existing home-family link.
Existing invitations add a membership and preserve the invitee's home family;
they no longer transfer owned accounts or provider items. The legacy `family`
association remains available for background jobs and compatibility code.

The intended initial layout is one private family plus two WG families. Keep
invitations disabled during rollout until the native family list and API access
tests have passed against the deployed image.
