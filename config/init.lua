-- Batch-review AUR upgrades once before yay builds any package.
-- Explicit installs retain yay's normal package-level menus.

local home = os.getenv("HOME") or ""
local helper = os.getenv("YAY_CODEX_REVIEW_HELPER") or
  (home .. "/.local/lib/yay-codex-review/yay-codex-review")
local manifest = os.getenv("YAY_CODEX_REVIEW_MANIFEST")
local accepted_unreviewed = false

local function shell_quote(value)
  return "'" .. value:gsub("'", "'\\''") .. "'"
end

local function run_helper(arguments)
  local parts = { shell_quote(helper) }
  for _, argument in ipairs(arguments) do
    parts[#parts + 1] = shell_quote(argument)
  end

  local status, kind, code = os.execute(table.concat(parts, " "))
  return status == 0 or (status == true and (code == nil or code == 0 or (kind == "exit" and code == 0)))
end

if manifest then
  -- A transaction-aware wrapper already reviewed this complete explicit set.
  yay.opt.diff_menu = false
  yay.opt.double_confirm = false
  yay.opt.edit_menu = false
end

yay.create_autocmd("UpgradeSelect", {
  desc = "review all AUR upgrades with Codex as one batch",
  callback = function(event)
    local bases = {}
    local seen_bases = {}

    local function collect(package)
      if package.repository ~= "aur" then
        return
      end

      local name = package.name
      local base = package.base
      if (not base or base == "") then
        base = name
      end

      if base and not seen_bases[base] then
        seen_bases[base] = true
        bases[#bases + 1] = base
      end
    end

    for _, package in ipairs(event.data.upgrades or {}) do
      collect(package)
    end
    for _, package in ipairs(event.data.pulled_dependencies or {}) do
      collect(package)
    end

    if #bases == 0 then
      return
    end

    manifest = os.tmpname()
    local args = { "review", manifest }
    for _, base in ipairs(bases) do
      args[#args + 1] = base
    end

    if not run_helper(args) then
      yay.abort("Codex review declined or unavailable; update cancelled before AUR builds")
    end

    -- The batch review replaces the per-package diff and repeat confirmation.
    yay.opt.diff_menu = false
    yay.opt.double_confirm = false
    yay.opt.edit_menu = false

    return { exclude = {}, skip_menu = true }
  end,
})

yay.create_autocmd("AURPreInstall", {
  desc = "verify each AUR PKGBUILD matches the batch Codex review",
  callback = function(event)
    if not manifest then
      return
    end

    local ok = run_helper({
      "verify",
      manifest,
      event.data.base,
      event.data.pkgbuild_path,
      event.data.srcinfo_path,
      event.data.dir,
    })

    if not ok and not accepted_unreviewed then
      if not run_helper({ "confirm-unreviewed", event.data.base }) then
        yay.abort(event.data.base .. ": unreviewed or changed AUR files were declined")
      end
      accepted_unreviewed = true
    end
  end,
})

yay.create_autocmd("PostInstall", {
  desc = "mark completed package transactions for the yay wrapper",
  callback = function(event)
    local marker = os.getenv("YAY_CLEANUP_POSTINSTALL_MARKER")
    if not marker or marker == "" or not event.data or #(event.data.packages or {}) == 0 then
      return
    end

    local file = io.open(marker, "w")
    if file then
      file:write("transaction completed\n")
      file:close()
    end
  end,
})
