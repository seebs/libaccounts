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
if not Library.LibAccounts then Library.LibAccounts = Accounts end

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
function Accounts.available_chars(acct_only)
  local availables = {}
  local visited = {}
  Accounts.table_init()
  -- First, we add everything on this account
  if not Accounts.here or not Accounts.here.accounts[Accounts.acctid] then
    Accounts.printf("Warning:  Tried to find available chars, didn't find any.")
    return availables
  end
  Accounts.populate(availables, visited, Accounts.acctid, acct_only)
  return availables
end

function Accounts.available_p(charname, acct_only)
  local availables = Accounts.available_chars(acct_only)
  charname = string.lower(charname)
  for _, row in ipairs(availables) do
    if string.lower(row.char) == charname then
      return true
    end
  end
  return false
end

function Accounts.populate(availables, visited, acctid, acct_only)
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
    table.insert(availables, { char = char, faction = faction, acctid = acctid })
  end
  if not acct_only then
    for other_acct, chars in pairs(Accounts.here.accounts) do
      local matched_faction = false
      for char, faction in pairs(chars) do
        if factions[faction] then
          matched_faction = true
	  break
        end
      end
      if matched_faction then
        Accounts.populate(availables, visited, other_acct, acct_only)
      end
    end
  end
end

function Accounts.acct_of(charname)
  if not charname then
    local me = Inspect.Unit.Detail("player")
    charname = (me and me.name) or "Unknown"
  end
  charname = string.lower(charname)
  Accounts.table_init()
  for acct, tab in pairs(Accounts.here.accounts) do
    for char, faction in pairs(tab) do
      if string.lower(char) == charname then
        return acct
      end
    end
  end
  return nil
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
      row.char, row.faction, row.acctid)
  end
end

Library.LibGetOpt.makeslash("", "LibAccounts", "accounts", Accounts.slashcommand)
table.insert(Event.Addon.SavedVariables.Load.End, { Accounts.variables_loaded, "LibAccounts", "variable loaded hook" })
