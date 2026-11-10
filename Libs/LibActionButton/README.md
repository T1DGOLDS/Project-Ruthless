# Bundled action-button libraries

Bundled for Forever only, reviewed 2026-11-08. No external addon installation is required.

- LibActionButton-1.0, minor 168: https://github.com/Nevcairiel/LibActionButton-1.0/blob/master/LibActionButton-1.0.lua . BSD 3-Clause, see LibActionButton-LICENSE.txt and the retained source header.
- LibStub, minor 2, revision 103: https://github.com/lua-wow/LibStub/blob/master/LibStub.lua . Public Domain declaration retained in source.
- CallbackHandler-1.0, minor 8, revision 25: https://github.com/WoWUIDev/Ace3/blob/master/CallbackHandler-1.0/CallbackHandler-1.0.lua . BSD 3-Clause, see CallbackHandler-LICENSE.txt.

Local modifications: LibStub's registry global is renamed to RUIActionBarLibStub. CallbackHandler and LibActionButton locally alias that registry instead of the public LibStub. Other library code is unchanged. Optional libraries are unavailable in the private registry. Upstream links identify provenance, while the bundled version and hashes identify the exact reviewed files.

SHA-256 of bundled, locally isolated files:

- LibStub.lua: `6cb9e494ba43688bb2ceb8539fd8d10b890d2d51f08e4d8b4086cd90db2c96df`
- CallbackHandler-1.0.lua: `c4d72ebfb5296c367e7587bc6d4e0aa6db211722a52622a23d93b0d3c73ccafb`
- LibActionButton-1.0.lua: `164cab1c8c445a1e56a916fe38e1a529f580c746a81920a4a54882f498c5e1e9`
