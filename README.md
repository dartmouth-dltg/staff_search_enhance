Staff Search Enhance
====================

An ArchivesSpace plugin that enhances the staff search interface by changing from a table view
to a more familiar and easy to use list view.

## Installing it

To install, just activate the plugin in your config/config.rb file by
including an entry such as:

     # If you have other plugins loaded, just add 'staff_search_enhance' to
     # the list
     AppConfig[:plugins] = ['local', 'other_plugins', 'staff_search_enhance']

And then add the `staff_search_enhance` repository into your
ArchivesSpace plugins directory.


## Database Migration

This plugin requires your Archival Objects, Resources and Accessions to be re-indexed.  This is triggered by running the plugin's
database migration via the command:

     cd /path/to/archivesspace
     scripts/setup-database.sh