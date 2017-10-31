# InternalPsModuleTemplate

A very light Plaster template for internal PowerShell module:

- No PSGallery
- No documentation
- No license

You can choose some features:
- Code directories (_public_, _private_, _classes_, _resources_)
- _Schemas_ directory (in project root)
- Module with/without _manifest_ file

## Note

Every script file MUST contains only ONE function (or ONE class).
This permits to export automatically public functions (through the deploy script).