# InternalPsModuleTemplate

A very light Plaster template for internal PowerShell module:

- PSM file in root project for smart debug
- Tests scaffold
- CD scripts (build + test)
- No PSGallery
- No mkdocs
- No license insertion

You can choose some features:
- Code directories (_public_, _private_, _classes_, _resources_)
- _Schemas_ directory (in project root)
- Module with/without _manifest_ file

## Note

Every script file MUST contains only ONE function (or ONE class).
This permits to export automatically public functions (through the deploy script).