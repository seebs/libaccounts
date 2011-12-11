--[[ LibAccounts
  hooks for identifying which account you're on
  LibAccountsGlobal = {
    next_id = N,
    shards = {
      shard = {
        chars = { char = acctid, ... },
        accounts = { acctid = { char = faction, ... }, ... }
      }
    }
  }
  LibAccountsAccount = {
    id = N
  }
]]--

if not Library then Library = {} end
local Accounts = {}
Accounts.shard = "Unknown"
if not Library.LibAccount then Library.LibAccount = Account end

Accounts.DebugLevel = 0
Accounts.Version = "VERSION"

function Accounts.debug(level, text, ...)
  if (level <= Accounts.DebugLevel) then
    print(string.format(text or 'nil', ...))
  end
end

function Accounts.printf(text, ...)
  print(string.format(text or 'nil', ...))
end

function Accounts.table_init()
  local ishard = Inspect.Shard()
  local shard = (ishard and ishard.name) or "Unknown"
  if shard ~= "Unknown" then
    Accounts.shard = shard
  end
  if not LibAccountsGlobal.shards then
    LibAccountsGlobal.shards = {}
    LibAccountsGlobal.shards[shard] = {
      chars = {},
      accounts = {},
    }
  end
  Accounts.here = LibAccountsGlobal.shards[shard]
  if not Accounts.here.accounts[Accounts.acctid] then
    Accounts.here.accounts[Accounts.acctid] = {}
  end
  local me = Inspect.Unit.Detail("player")
  if me then
    Accounts.here.chars[me.name] = Accounts.acctid
    Accounts.here.accounts[Accounts.acctid][me.name] = me.faction
  end
end

function Accounts.variables_loaded(name)
  if name ~= 'LibAccounts' then
    return
  end
  if not LibAccountsGlobal then
    LibAccountsGlobal = {
      next_id = 1,
      chars = {},
      accounts = {}
    }
  end
  if not LibAccountsAccount then
    LibAccountsAccount = {
      id = LibAccountsGlobal.next_id
    }
    LibAccountsGlobal.next_id = LibAccountsGlobal.next_id + 1
  end
  Accounts.acctid = LibAccountsAccount.id
end

-- identifies all the characters on this shard that can be reached
-- from the current character
function Accounts.available_chars()
  local availables = {}
  local visited = {}
  -- First, we add everything on this account
  if not Accounts.here or not Accounts.here.accounts[Accounts.acctid] then
    Accounts.printf("Warning:  Tried to find available chars, didn't find any.")
    return availables
  end
  Accounts.populate(availables, visited, Accounts.acctid)
  return availables
end

function Accounts.populate(availables, visited, acctid)
  local factions = {}
  if visited[acctid] then
    return
  end
  if not Accounts.here.accounts or not Accounts.here.accounts[acctid] then
    return
  end
  visited[acctid] = true
  for char, faction in pairs(Accounts.here.accounts[acctid]) do
    factions[faction] = true
    table.insert(availables, { char, faction, acctid })
  end
  for other_acct, chars in pairs(Accounts.here.accounts) do
    local matched_faction = false
    for char, faction in pairs(chars) do
      if factions[faction] then
        matched_faction = true
	break
      end
    end
    if matched_faction then
      Accounts.populate(availables, visited, other_acct)
    end
  end
end

function Accounts.slashcommand(args)
  Accounts.table_init()
  Accounts.printf("Dumping account info for %s:", Accounts.shard)
  if not Accounts.here then
    Accounts.printf("... No info?")
    return
  end
  for acct, tab in pairs(Accounts.here.accounts) do
    Accounts.printf("Account #%d:", acct)
    for char, faction in pairs(tab) do
      Accounts.printf("  %s (%s)", char, faction)
    end
  end
  Accounts.printf("Available characters:")
  local chars = Accounts.available_chars()
  for _, row in ipairs(chars) do
    Accounts.printf("  %s (%s, acct %d)",
      row[1], row[2], row[3])
  end
end

Library.LibGetOpt.makeslash("", "LibAccounts", "accounts", Accounts.slashcommand)
table.insert(Event.Addon.SavedVariables.Load.End, { Accounts.variables_loaded, "LibAccounts", "variable loaded hook" })
