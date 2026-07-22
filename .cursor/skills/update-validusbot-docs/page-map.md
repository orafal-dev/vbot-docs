# Spec / core → docs page map

Use this when deciding which hand-written pages to edit after a sync.

## Getting started

| Topic | Page |
| --- | --- |
| Product intro / principles | `apps/docs/content/docs/index.mdx` |
| Scripts folder + core loading | `getting-started/overview.mdx` |
| Runtime model, cooperative yield | `getting-started/runtime.mdx` |
| Hard rules + checklist | `getting-started/safety.mdx` |
| Recommended template | `getting-started/template.mdx` |
| Practical examples | `apps/docs/content/docs/examples.mdx` |

## Guides ↔ core modules

| Core / spec module | Guide |
| --- | --- |
| `module.lua` | `guides/module-scheduling.mdx` |
| `self.lua`, `game.lua` | `guides/self.mdx` |
| `creature.lua`, `creature_iterators.lua` | `guides/creatures.mdx` |
| `map.lua`, `minimap.lua`, `position.lua` | `guides/map-navigation.mdx` |
| `item.lua`, `container.lua`, `inventory.lua`, `npc_trade_storage.lua` | `guides/items-containers.mdx` |
| `spells.lua`, `cooldowns.lua` | `guides/spells-cooldowns.mdx` |
| `cavebot.lua`, `cavebot_actions.lua` | `guides/cavebot.mdx` |
| `engine.lua`, `features.lua`, Engine feature-control API | `guides/engine-features.mdx` |
| `http.lua`, `websocket.lua`, `json.lua` | `guides/networking.mdx` |
| `storage.lua` | `guides/storage.mdx` |
| `chat_channel.lua`, `chat_channel_storage.lua`, `vip.lua`, `sound.lua` | `guides/communication.mdx` |
| `event_proxies.lua`, `hud_wrapper.lua` | `guides/events-hud.mdx` |
| `lua_consts.lua`, Critical Constants | `guides/constants.mdx` |
| `hotkeys.lua` | fold into `guides/module-scheduling.mdx` or `events-hud.mdx` if constraints change; API page is generated |

## Generated API reference

| Core file | API slug |
| --- | --- |
| `cavebot.lua` | `api-reference/cavebot` |
| `cavebot_actions.lua` | `api-reference/cavebot-actions` |
| `chat_channel.lua` | `api-reference/chat-channel` |
| `chat_channel_storage.lua` | `api-reference/chat-channel-storage` |
| `container.lua` | `api-reference/container` |
| `cooldowns.lua` | `api-reference/cooldowns` |
| `creature.lua` | `api-reference/creature` |
| `creature_iterators.lua` | `api-reference/creatures` |
| `engine.lua` | `api-reference/engine` |
| `event_proxies.lua` | `api-reference/event-proxies` |
| `features.lua` | `api-reference/features` |
| `game.lua` | `api-reference/game` |
| `hotkeys.lua` | `api-reference/hotkeys` |
| `http.lua` | `api-reference/http` |
| `hud_wrapper.lua` | `api-reference/hud` |
| `inventory.lua` | `api-reference/inventory` |
| `item.lua` | `api-reference/item` |
| `json.lua` | `api-reference/json` |
| `lua_consts.lua` | `api-reference/constants` |
| `map.lua` | `api-reference/map` |
| `minimap.lua` | `api-reference/minimap` |
| `module.lua` | `api-reference/module` |
| `npc_trade_storage.lua` | `api-reference/npc-trade` |
| `position.lua` | `api-reference/position` |
| `self.lua` | `api-reference/self` |
| `sound.lua` | `api-reference/sound` |
| `spells.lua` | `api-reference/spells` |
| `storage.lua` | `api-reference/storage` |
| `vip.lua` | `api-reference/vip` |
| `websocket.lua` | `api-reference/websocket` |

Slugs come from `MODULE_SLUGS` in `apps/docs/scripts/generate-api-reference.py`.
