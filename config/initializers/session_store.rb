# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_judge_session',
  :secret      => 'ab12765879af343d010ac9ec70a0ff5e5c0d9410d91d51c0d4d2435a2084644c2566578bceffa9863665b29d1753b27451446c0f6dc874bf6faa210b847064ba'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
