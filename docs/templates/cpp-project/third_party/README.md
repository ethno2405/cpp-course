# Third-Party Code

This file lists every library that the project uses. Keep it up to date. See `docs/topics/external-libraries.md` in the course repository for the rules.

| Library | Version | Source | SHA-256 of the downloaded file | License | Method | Patches |
|---|---|---|---|---|---|---|
| doctest | 2.4.11 | github.com/doctest/doctest, release `v2.4.11`, file `doctest/doctest.h` | <write the hash that you computed> | MIT (`doctest/LICENSE.txt`) | Vendored header | None |

## Add doctest

1. Open the release page of doctest on GitHub. Select a release, for example `v2.4.11`. Use the newest release if it is newer, and write its version in the table.
2. Download the single header `doctest/doctest.h` and the file `LICENSE.txt` of that release tag. Do not use the `master` branch: it can change.
3. Put the files here:

   ```
   third_party/doctest/doctest/doctest.h
   third_party/doctest/LICENSE.txt
   ```

4. Compute the SHA-256 hash of `doctest.h` and write it in the table:

   ```sh
   sha256sum third_party/doctest/doctest/doctest.h        # Linux
   shasum -a 256 third_party/doctest/doctest/doctest.h    # macOS
   ```

   ```powershell
   Get-FileHash third_party/doctest/doctest/doctest.h -Algorithm SHA256
   ```

5. Commit the files together with this table.

Do not change the vendored files. If a library needs a change, keep the patch as a separate file in `third_party/patches/` and list it in the table.
