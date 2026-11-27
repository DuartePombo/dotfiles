-- headphones-take-over: when Bluetooth headphones connect, they become the chosen speaker and microphone, like on a
-- phone. A pick made meanwhile (the audio-switch menu, Super+A, or Volume Control's ✓) lasts until the next time
-- headphones connect. Without this, WirePlumber keeps the last pick for good: it ranks every past pick above the
-- normal priorities, so after choosing the laptop once, newly connected headphones would stay silent.
-- Headphones change their speaker and microphone when they switch between music and call mode: those are the same
-- headphones, so they don't take over again (a switch to the laptop survives a call starting).
-- Registered in ~/.config/wireplumber/wireplumber.conf.d/53-headphones-take-over.conf.

log = Log.open_topic ("s-custom-headphones")

-- "<device id>/<audio.sink|audio.source>" → true while those headphones stay connected
local handled = {}

local function choose (event, key)
  local props = event:get_subject ().properties
  local dev = props ["device.id"]
  local name = props ["node.name"]
  if dev == nil or name == nil then
    return
  end
  local tag = dev .. "/" .. key
  if handled [tag] then
    return
  end
  handled [tag] = true

  local om = event:get_source ():call ("get-object-manager", "metadata")
  local metadata = om:lookup { Constraint { "metadata.name", "=", "default" } }
  if metadata == nil then
    return
  end
  log:info ("headphones connected: " .. name .. " becomes default." .. key)
  metadata:set (0, "default.configured." .. key, "Spa:String:JSON",
      Json.Object { ["name"] = name }:to_string ())
end

SimpleEventHook {
  name = "custom/headphones-take-over-speaker",
  interests = {
    EventInterest {
      Constraint { "event.type", "=", "node-added" },
      Constraint { "media.class", "=", "Audio/Sink" },
      Constraint { "api.bluez5.address", "+", type = "pw" },
    },
  },
  execute = function (event) choose (event, "audio.sink") end
}:register ()

-- the headphones' microphone as WirePlumber always shows it (its stand-in, present in music and call mode)
SimpleEventHook {
  name = "custom/headphones-take-over-microphone",
  interests = {
    EventInterest {
      Constraint { "event.type", "=", "node-added" },
      Constraint { "media.class", "=", "Audio/Source" },
      Constraint { "bluez5.loopback", "=", "true", type = "pw" },
    },
  },
  execute = function (event) choose (event, "audio.source") end
}:register ()

-- disconnected: the next connection takes over again
SimpleEventHook {
  name = "custom/headphones-take-over-forget",
  interests = {
    EventInterest {
      Constraint { "event.type", "=", "device-removed" },
    },
  },
  execute = function (event)
    local id = tostring (event:get_subject () ["bound-id"])
    handled [id .. "/audio.sink"] = nil
    handled [id .. "/audio.source"] = nil
  end
}:register ()
