# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)


public = Public.create id: 'public', name: 'Public', visibility: ['public'], slugs: ['public'], display_slug: 'public'
system = System.create id: 'system', name: 'System', visibility: ['system'], slugs: ['system', 'my3-user-1'], display_slug: 'system'
guest = Guest.create id: 'guest', name: 'Guest', visibility: ['guest'], slugs: ['guest', 'my3-user-2'], display_slug: 'guest'
unknown = Unknown.create id: 'unknown', name: 'Unknown', visibility: ['unknown'], slugs: ['unknown'p], display_slug: 'unknown'


