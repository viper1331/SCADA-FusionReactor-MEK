-- Optional CCMSI source override.
-- Rename to `ccmsi_source.lua` to activate.
--
-- For installs directly from a repository copy on ComputerCraft:
-- keep `use_local_files = true`.
--
-- For installs from a hosted fork:
-- set manifest_path and repo_path to your own URLs, then use `use_local_files = false`.

return {
    -- true: read install_manifest.json + files from local repository checkout
    -- false: download from manifest_path/repo_path
    use_local_files = true,

    -- Example for a hosted fork (replace values):
    -- manifest_path = "https://<user>.github.io/<repo>/manifests/",
    -- repo_path = "https://raw.githubusercontent.com/<user>/<repo>/"
}
