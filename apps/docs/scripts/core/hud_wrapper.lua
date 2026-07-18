-- ============================================================================
-- File: scripts/core/hud_wrapper.lua
-- Complete HUD Wrapper Library for ValidusBot Lua Scripting Engine
-- ============================================================================
-- This library provides object-oriented wrappers around the low-level C++ HUD
-- API, making it easier to create and manage HUD elements with a builder pattern.
-- 
-- Supported Element Types:
--   - ScreenText: 2D text overlay anchored to screen coordinates
--   - WorldText: 3D text anchored to world coordinates
--   - WorldBox: 3D colored rectangle anchored to world coordinates
-- ============================================================================

-- ============================================================================
-- ALIGNMENT CONSTANTS
-- ============================================================================

--- Horizontal text alignment flags (bit flags, can be combined)
HorizontalAlignment = {
    LEFT = 1,      -- Align text to the left edge
    RIGHT = 2,     -- Align text to the right edge
    CENTER = 4,    -- Center text horizontally
    JUSTIFY = 8    -- Justify text (stretch to fill available width)
}

--- Vertical text alignment flags (bit flags, can be combined)
VerticalAlignment = {
    TOP = 32,       -- Align text to the top edge
    BOTTOM = 64,    -- Align text to the bottom edge
    CENTER = 128,   -- Center text vertically
    BASELINE = 256  -- Align text to baseline (for precise typography)
}

local function hud_element_id(value, functionName)
    if type(value) == "string" and value ~= "" then
        return value
    end
    if type(value) == "table" and type(value.id) == "string" and value.id ~= "" then
        return value.id
    end
    error(functionName .. ": target must be a HUD element or non-empty element id")
end

-- ============================================================================
-- SCREEN TEXT - Text anchored to screen coordinates (2D overlay)
-- ============================================================================

---@class ScreenText
---@field id string Unique identifier for this element
---@field text string Text content to display
---@field color table Color table with r, g, b, a fields (0-255)
---@field h_align number Horizontal alignment (HorizontalAlignment enum)
---@field v_align number Vertical alignment (VerticalAlignment enum)
---@field is_draggable boolean Whether element can be dragged by user
---@field is_clickable boolean Whether element responds to mouse clicks
---@field enabled boolean Whether element is visible
---@field z_index number Draw order; higher values render and receive clicks above lower values
---@field parent_id string|nil Optional parent element id for visibility/remove cascades
---@field screen_x number|nil Explicit screen X position applied at creation
---@field screen_y number|nil Explicit screen Y position applied at creation
---@field _created boolean Internal flag tracking if element exists in C++
---@field _clickCallback function Internal storage for click callback
ScreenText = {}
ScreenText.__index = ScreenText

--- Creates a new screen text element.
--- Screen text is rendered as a 2D overlay on the screen at fixed positions.
--- The element is not created until :Create() is called.
---@param id string Unique identifier within this script
---@return ScreenText A new ScreenText instance (not yet created in C++)
---@usage local myText = ScreenText:New("health_display")
function ScreenText:New(id)
    local element = {
        -- Required fields
        id = id,
        text = "",
        
        -- Visual properties with sensible defaults
        color = { r = 255, g = 255, b = 255, a = 255 },  -- White, fully opaque
        h_align = HorizontalAlignment.LEFT,
        v_align = VerticalAlignment.TOP,
        
        -- Interaction properties
        is_draggable = false,
        is_clickable = false,
        enabled = true,
        z_index = 0,
        parent_id = nil,
        drag_target_id = nil,
        screen_x = nil,
        screen_y = nil,
        
        -- Internal state management
        _created = false,
        _clickCallback = nil,
        _dragEndCallback = nil
    }
    setmetatable(element, ScreenText)
    return element
end

--- Sets the text content.
--- If called before :Create(), the text will be set when the element is created.
--- If called after :Create(), the text is immediately updated in C++.
---@param text string The text to display
---@return ScreenText Returns self for method chaining
---@usage myText:SetText("HP: 100%")
function ScreenText:SetText(text)
    self.text = text
    if self._created then
        HUD.UpdateText(self.id, text)
    end
    return self
end

--- Sets the text color.
--- Color components should be integers in range 0-255.
---@param color table Color table with fields {r, g, b, a}
---@return ScreenText Returns self for method chaining
---@usage myText:SetColor({ r = 255, g = 0, b = 0, a = 255 }) -- Red
function ScreenText:SetColor(color)
    self.color = color
    if self._created then
        HUD.UpdateColor(self.id, color)
    end
    return self
end

--- Sets the text alignment relative to its anchor point.
--- Alignment affects how the text is positioned relative to its coordinates.
---@param h_align number Horizontal alignment (HorizontalAlignment.*)
---@param v_align number Vertical alignment (VerticalAlignment.*)
---@return ScreenText Returns self for method chaining
---@usage myText:SetAlignment(HorizontalAlignment.RIGHT, VerticalAlignment.TOP)
function ScreenText:SetAlignment(h_align, v_align)
    self.h_align = h_align
    self.v_align = v_align
    if self._created then
        HUD.SetAlignment(self.id, h_align, v_align)
    end
    return self
end

--- Makes the element draggable by the user with the mouse.
--- When draggable, users can click and drag the element to reposition it on screen.
---@param draggable boolean True to enable dragging, false to disable
---@return ScreenText Returns self for method chaining
---@usage myText:SetDraggable(true)
function ScreenText:SetDraggable(draggable)
    self.is_draggable = draggable
    if self._created then
        HUD.SetDraggable(self.id, draggable)
    end
    return self
end

--- Makes this element a drag handle for another screen HUD element.
--- Pass nil to make the element move itself again.
---@param target ScreenText|ScreenImage|string|nil Target element or element id
---@return ScreenText
function ScreenText:SetDragTarget(target)
    self.drag_target_id = target == nil and nil or hud_element_id(target, "ScreenText:SetDragTarget")
    if self._created then
        HUD.SetDragTarget(self.id, self.drag_target_id)
    end
    return self
end

--- Runs after a drag finishes. The callback receives final target x and y coordinates.
---@param callback function|nil Callback function(x, y), or nil to clear it
---@return ScreenText
function ScreenText:SetOnDragEnd(callback)
    if callback ~= nil and callback ~= false and type(callback) ~= "function" then
        error("ScreenText:SetOnDragEnd: callback must be a function, false, or nil")
    end
    self._dragEndCallback = callback or nil
    if self._created then
        HUD.SetOnDragEnd(self.id, self._dragEndCallback)
    end
    return self
end

--- Makes the element clickable and sets the callback function.
--- The callback is executed in a new coroutine when the user clicks on the element.
---@param callback function Function to call on click (no parameters)
---@return ScreenText Returns self for method chaining
---@usage myText:SetClickable(function() print("Clicked!") end)
function ScreenText:SetClickable(callback)
    if callback == nil or callback == false then
        self.is_clickable = false
        self._clickCallback = nil
        if self._created then
            HUD.SetClickable(self.id, false, nil)
        end
    elseif type(callback) == "function" then
        self.is_clickable = true
        self._clickCallback = callback
        if self._created then
            HUD.SetClickable(self.id, true, callback)
        end
    else
        error("SetClickable: argument must be nil, false, or a function")
    end
    return self  -- Method chaining
end

--- Sets the screen position in pixels from top-left corner.
--- If called before :Create(), the position is applied immediately after creation.
---@param x number X coordinate in pixels (0 = left edge of screen)
---@param y number Y coordinate in pixels (0 = top edge of screen)
---@return ScreenText Returns self for method chaining
---@usage myText:SetScreenPosition(100, 50)
function ScreenText:SetScreenPosition(x, y)
    self.screen_x = x
    self.screen_y = y
    if self._created then
        HUD.SetScreenPosition({
            id = self.id,
            x = x,
            y = y
        })
    end
    return self
end

--- Sets the logical parent element for this screen text.
--- When the parent is hidden, disabled, or removed, this child follows it.
--- When the parent is moved by screen position or dragging, this child keeps its current offset.
--- The parent and child must belong to the same script/HUD owner.
---@param parent ScreenText|ScreenImage|string Parent element or element id
---@return ScreenText Returns self for method chaining
---@usage childText:SetParent(parentText.id)
function ScreenText:SetParent(parent)
    self.parent_id = hud_element_id(parent, "ScreenText:SetParent")
    if self._created then
        HUD.SetParent(self.id, self.parent_id)
    end
    return self
end

--- Clears the logical parent relationship for this screen text.
--- After clearing, the element visibility is controlled only by its own enabled state.
---@return ScreenText Returns self for method chaining
---@usage childText:ClearParent()
function ScreenText:ClearParent()
    self.parent_id = nil
    if self._created then
        HUD.ClearParent(self.id)
    end
    return self
end

--- Sets whether the element is visible/enabled.
--- Disabled elements are not rendered but still exist in memory.
---@param enabled boolean True to show the element, false to hide it
---@return ScreenText Returns self for method chaining
---@usage myText:SetEnabled(false) -- Hide the element
function ScreenText:SetEnabled(enabled)
    self.enabled = enabled
    if self._created then
        HUD.SetEnabled(self.id, enabled)
    end
    return self
end

--- Sets draw order for this screen text.
--- Higher values render and receive clicks above lower values.
---@param zIndex number Integer draw order
---@return ScreenText Returns self for method chaining
function ScreenText:SetZIndex(zIndex)
    self.z_index = zIndex
    if self._created then
        HUD.SetZIndex(self.id, zIndex)
    end
    return self
end

--- Creates the element in C++ (sends creation request to HUD system).
--- This must be called after configuring all properties using the builder methods.
--- After calling this, the element will be rendered on screen.
---@return ScreenText Returns self for method chaining
---@usage myText:Create()
function ScreenText:Create()
    -- Send creation request to C++ HUD system
    HUD.AddScreenText({
        id = self.id,
        text = self.text,
        color = self.color,
        h_align = self.h_align,
        v_align = self.v_align,
        is_draggable = self.is_draggable,
        is_clickable = self.is_clickable,
        on_click = self._clickCallback,
        enabled = self.enabled,
        z_index = self.z_index
    })

    self._created = true
    if type(self.screen_x) == "number" and type(self.screen_y) == "number" then
        HUD.SetScreenPosition({
            id = self.id,
            x = self.screen_x,
            y = self.screen_y
        })
    end
    if self.parent_id ~= nil then
        HUD.SetParent(self.id, self.parent_id)
    end
    if self.drag_target_id ~= nil then
        HUD.SetDragTarget(self.id, self.drag_target_id)
    end
    if self._dragEndCallback ~= nil then
        HUD.SetOnDragEnd(self.id, self._dragEndCallback)
    end
    return self
end

--- Removes the element from the screen.
--- After removal, the element can be recreated with :Create().
---@usage myText:Remove()
function ScreenText:Remove()
    if self._created then
        HUD.RemoveElement(self.id)
        self._created = false
    end
end

--- Checks if the element has been created in C++.
---@return boolean True if element exists in C++, false otherwise
---@usage if myText:IsCreated() then print("Element exists") end
function ScreenText:IsCreated()
    return self._created
end

--- Queries if the element is enabled (async await-style)
--- Must be called from within a coroutine
---@return boolean True if enabled, false otherwise
---@usage local enabled = myText:GetEnabled()
function ScreenText:GetEnabled()
    return HUD.GetElementEnabled(self.id)
end

--- Queries if the element is visible
---@return boolean True if visible, false otherwise
function ScreenText:GetVisible()
    return HUD.GetElementVisible(self.id)
end

--- Queries the current text content
---@return string The current text
function ScreenText:GetText()
    return HUD.GetElementText(self.id)
end

--- Queries the current color
---@return table Color table {r, g, b, a}
function ScreenText:GetColor()
    return HUD.GetElementColor(self.id)
end

--- Queries the current screen position
---@return table Position table {x, y}
function ScreenText:GetPosition()
    return HUD.GetScreenElementPosition(self.id)
end

--- Queries the element width
---@return number Width in pixels
function ScreenText:GetWidth()
    return HUD.GetElementWidth(self.id)
end

--- Queries the element height
---@return number Height in pixels
function ScreenText:GetHeight()
    return HUD.GetElementHeight(self.id)
end


-- ============================================================================
-- WORLD TEXT - Text anchored to world coordinates (3D position in game)
-- ============================================================================

---@class WorldText
---@field id string Unique identifier for this element
---@field x number World X coordinate
---@field y number World Y coordinate
---@field z number World Z coordinate (floor level)
---@field text string Text content to display
---@field color table Color table with r, g, b, a fields (0-255)
---@field lifetime_ms number Auto-removal time in milliseconds (0 = permanent)
---@field offset_x number Pixel offset from world position (X axis)
---@field offset_y number Pixel offset from world position (Y axis)
---@field enabled boolean Whether element is visible
---@field z_index number Draw order; higher values render above lower values
---@field parent_id string|nil Optional parent element id for visibility/remove cascades
---@field _created boolean Internal flag tracking if element exists in C++
WorldText = {}
WorldText.__index = WorldText

--- Creates a new world text element.
--- World text is anchored to 3D coordinates in the game world and moves with the camera.
--- Useful for labeling items, monsters, or locations in the game world.
---@param id string Unique identifier (must be unique across all HUD elements)
---@param x number World X coordinate
---@param y number World Y coordinate
---@param z number World Z coordinate (floor level, typically 0-15)
---@return WorldText A new WorldText instance (not yet created in C++)
---@usage local label = WorldText:New("item_label", 1024, 1025, 7)
function WorldText:New(id, x, y, z)
    local element = {
        -- Required fields
        id = id,
        x = x,
        y = y,
        z = z,
        text = "",
        
        -- Visual properties with sensible defaults
        color = { r = 255, g = 255, b = 255, a = 255 },  -- White, fully opaque
        offset_x = 0.0,
        offset_y = 0.0,
        
        -- Lifetime management (0 = permanent)
        lifetime_ms = 0,
        
        -- State
        enabled = true,
        z_index = 0,
        parent_id = nil,
        _created = false
    }
    setmetatable(element, WorldText)
    return element
end

--- Sets the text content.
--- Can be called before or after :Create().
---@param text string The text to display
---@return WorldText Returns self for method chaining
---@usage label:SetText("Magic Sword")
function WorldText:SetText(text)
    self.text = text
    if self._created then
        HUD.UpdateText(self.id, text)
    end
    return self
end

--- Sets the text color.
--- Color components should be integers in range 0-255.
---@param color table Color table with fields {r, g, b, a}
---@return WorldText Returns self for method chaining
---@usage label:SetColor({ r = 255, g = 215, b = 0, a = 255 }) -- Gold
function WorldText:SetColor(color)
    self.color = color
    if self._created then
        HUD.UpdateColor(self.id, color)
    end
    return self
end

--- Updates the world position of the text.
--- The text will move to the new 3D coordinate in the game world.
---@param x number World X coordinate
---@param y number World Y coordinate
---@param z number World Z coordinate (floor level)
---@return WorldText Returns self for method chaining
---@usage label:SetPosition(1025, 1026, 7)
function WorldText:SetPosition(x, y, z)
    self.x = x
    self.y = y
    self.z = z
    if self._created then
        HUD.SetPosition({
            id = self.id,
            x = x,
            y = y,
            z = z
        })
    end
    return self
end

--- Updates the lifetime of the element
---@param lifetime_ms number Milliseconds before auto-removal (0 = permanent)
---@return WorldText|WorldBox Returns self for chaining
function WorldText:SetLifetime(lifetime_ms)
    self.lifetime_ms = lifetime_ms
    if self._created then
        HUD.UpdateLifetime(self.id, lifetime_ms)
    end
    return self
end

--- Updates the pixel offset from world position
---@param offset_x number Horizontal offset in pixels
---@param offset_y number Vertical offset in pixels
---@return WorldText|WorldBox Returns self for chaining
function WorldText:SetOffset(offset_x, offset_y)
    self.offset_x = offset_x
    self.offset_y = offset_y
    if self._created then
        HUD.UpdateOffset(self.id, offset_x, offset_y)
    end
    return self
end

--- Sets the logical parent element for this world text.
--- Parent visibility and removal cascade to this child without changing its world position.
---@param parent_id string Parent element id
---@return WorldText Returns self for method chaining
function WorldText:SetParent(parent_id)
    self.parent_id = parent_id
    if self._created then
        HUD.SetParent(self.id, parent_id)
    end
    return self
end

--- Clears the logical parent relationship for this world text.
---@return WorldText Returns self for method chaining
function WorldText:ClearParent()
    self.parent_id = nil
    if self._created then
        HUD.ClearParent(self.id)
    end
    return self
end

--- Sets whether the element is visible/enabled.
---@param enabled boolean True to show the element, false to hide it
---@return WorldText Returns self for method chaining
function WorldText:SetEnabled(enabled)
    self.enabled = enabled
    if self._created then
        HUD.SetEnabled(self.id, enabled)
    end
    return self
end

--- Sets draw order for this world text.
---@param zIndex number Integer draw order
---@return WorldText Returns self for method chaining
function WorldText:SetZIndex(zIndex)
    self.z_index = zIndex
    if self._created then
        HUD.SetZIndex(self.id, zIndex)
    end
    return self
end

--- Creates the element in C++ (sends creation request to HUD system).
--- Must be called after configuring all properties.
---@return WorldText Returns self for method chaining
---@usage label:Create()
function WorldText:Create()
    HUD.AddWorldText({
        id = self.id,
        x = self.x,
        y = self.y,
        z = self.z,
        text = self.text,
        color = self.color,
        lifetime_ms = self.lifetime_ms,
        offset_x = self.offset_x,
        offset_y = self.offset_y,
        enabled = self.enabled,
        z_index = self.z_index
    })
    
    self._created = true
    if self.parent_id ~= nil then
        HUD.SetParent(self.id, self.parent_id)
    end
    return self
end

--- Removes the element from the world.
---@usage label:Remove()
function WorldText:Remove()
    if self._created then
        HUD.RemoveElement(self.id)
        self._created = false
    end
end

--- Checks if the element has been created in C++.
---@return boolean True if element exists in C++
function WorldText:IsCreated()
    return self._created
end

--- Queries if the element is enabled
---@return boolean
function WorldText:GetEnabled()
    return HUD.GetElementEnabled(self.id)
end

--- Queries if the element is visible
---@return boolean
function WorldText:GetVisible()
    return HUD.GetElementVisible(self.id)
end

--- Queries the current text content
---@return string
function WorldText:GetText()
    return HUD.GetElementText(self.id)
end

--- Queries the current color
---@return table Color {r, g, b, a}
function WorldText:GetColor()
    return HUD.GetElementColor(self.id)
end

--- Queries the current world position
---@return table Position {x, y, z}
function WorldText:GetPosition()
    return HUD.GetWorldElementPosition(self.id)
end

--- Queries the element width
---@return number
function WorldText:GetWidth()
    return HUD.GetElementWidth(self.id)
end

--- Queries the element height
---@return number
function WorldText:GetHeight()
    return HUD.GetElementHeight(self.id)
end

-- ============================================================================
-- WORLD BOX - Colored rectangle anchored to world coordinates
-- ============================================================================

---@class WorldBox
---@field id string Unique identifier for this element
---@field x number World X coordinate
---@field y number World Y coordinate
---@field z number World Z coordinate (floor level)
---@field width number Box width in pixels (-1 for auto-size based on tile)
---@field height number Box height in pixels (-1 for auto-size based on tile)
---@field color table Fill color with r, g, b, a fields (0-255)
---@field border_width number Border thickness in pixels
---@field border_color table Border color with r, g, b, a fields (0-255)
---@field lifetime_ms number Auto-removal time in milliseconds (0 = permanent)
---@field enabled boolean Whether element is visible
---@field z_index number Draw order; higher values render above lower values
---@field parent_id string|nil Optional parent element id for visibility/remove cascades
---@field _created boolean Internal flag tracking if element exists in C++
WorldBox = {}
WorldBox.__index = WorldBox

--- Creates a new world box element.
--- World boxes are rectangular overlays anchored to 3D coordinates in the game world.
--- Useful for highlighting tiles, areas, danger zones, or objects.
---@param id string Unique identifier (must be unique across all HUD elements)
---@param x number World X coordinate
---@param y number World Y coordinate
---@param z number World Z coordinate (floor level)
---@return WorldBox A new WorldBox instance (not yet created in C++)
---@usage local marker = WorldBox:New("danger_tile", 1024, 1025, 7)
function WorldBox:New(id, x, y, z)
    local element = {
        -- Required fields
        id = id,
        x = x,
        y = y,
        z = z,
        
        -- Size properties (-1 = auto-size based on tile/object at position)
        width = -1.0,
        height = -1.0,
        
        -- Visual properties with sensible defaults
        color = { r = 0, g = 0, b = 0, a = 128 },  -- Semi-transparent black fill
        border_width = 0.0,
        border_color = { r = 255, g = 255, b = 255, a = 255 },  -- White border
        
        -- Lifetime management (0 = permanent)
        lifetime_ms = 0,
        
        -- State
        enabled = true,
        z_index = 0,
        parent_id = nil,
        _created = false
    }
    setmetatable(element, WorldBox)
    return element
end

--- Sets the box size in pixels.
--- Use -1 for auto-sizing based on the tile/object at the world position.
--- Can be called before or after :Create().
---@param width number Width in pixels (-1 for auto-size to tile width)
---@param height number Height in pixels (-1 for auto-size to tile height)
---@return WorldBox Returns self for method chaining
---@usage marker:SetSize(32, 32) -- 32x32 pixel box (standard tile size)
function WorldBox:SetSize(width, height)
    self.width = width
    self.height = height
    if self._created then
        -- Use separate update functions for width and height
        HUD.UpdateWidth(self.id, width)
        HUD.UpdateHeight(self.id, height)
    end
    return self
end

--- Sets just the width, keeping height unchanged.
---@param width number Width in pixels (-1 for auto-size)
---@return WorldBox Returns self for method chaining
---@usage marker:SetWidth(64)
function WorldBox:SetWidth(width)
    self.width = width
    if self._created then
        HUD.UpdateWidth(self.id, width)
    end
    return self
end

--- Sets just the height, keeping width unchanged.
---@param height number Height in pixels (-1 for auto-size)
---@return WorldBox Returns self for method chaining
---@usage marker:SetHeight(64)
function WorldBox:SetHeight(height)
    self.height = height
    if self._created then
        HUD.UpdateHeight(self.id, height)
    end
    return self
end

--- Sets the fill color of the box interior.
--- Color components should be integers in range 0-255.
---@param color table Color table with fields {r, g, b, a}
---@return WorldBox Returns self for method chaining
---@usage marker:SetColor({ r = 255, g = 0, b = 0, a = 100 }) -- Transparent red
function WorldBox:SetColor(color)
    self.color = color
    if self._created then
        HUD.UpdateColor(self.id, color)
    end
    return self
end

--- Sets just the border width, keeping color unchanged.
---@param border_width number Border thickness in pixels (0 = no border)
---@return WorldBox Returns self for method chaining
---@usage marker:SetBorderWidth(3)
function WorldBox:SetBorderWidth(border_width)
    self.border_width = border_width
    if self._created then
        HUD.UpdateBorderWidth(self.id, border_width)
    end
    return self
end

--- Sets just the border color, keeping width unchanged.
---@param border_color table Border color {r, g, b, a}
---@return WorldBox Returns self for method chaining
---@usage marker:SetBorderColor({ r = 255, g = 0, b = 0, a = 255 }) -- Red border
function WorldBox:SetBorderColor(border_color)
    self.border_color = border_color
    if self._created then
        HUD.UpdateBorderColor(self.id, border_color)
    end
    return self
end

--- Updates the world position of the box.
--- The box will move to the new 3D coordinate in the game world.
---@param x number World X coordinate
---@param y number World Y coordinate
---@param z number World Z coordinate (floor level)
---@return WorldBox Returns self for method chaining
---@usage marker:SetPosition(1025, 1026, 7)
function WorldBox:SetPosition(x, y, z)
    self.x = x
    self.y = y
    self.z = z
    if self._created then
        HUD.SetPosition({
            id = self.id,
            x = x,
            y = y,
            z = z
        })
    end
    return self
end

--- Sets the lifetime before automatic removal.
--- Useful for temporary markers or highlighting effects.
---@param lifetime_ms number Milliseconds before auto-removal (0 = never expires)
---@return WorldBox Returns self for method chaining
---@usage marker:SetLifetime(5000) -- Remove after 5 seconds
function WorldBox:SetLifetime(lifetime_ms)
    self.lifetime_ms = lifetime_ms
    -- Note: Lifetime is only applied at creation, not dynamically updatable
    return self
end

--- Sets the logical parent element for this world box.
--- Parent visibility and removal cascade to this child without changing its world position.
---@param parent_id string Parent element id
---@return WorldBox Returns self for method chaining
function WorldBox:SetParent(parent_id)
    self.parent_id = parent_id
    if self._created then
        HUD.SetParent(self.id, parent_id)
    end
    return self
end

--- Clears the logical parent relationship for this world box.
---@return WorldBox Returns self for method chaining
function WorldBox:ClearParent()
    self.parent_id = nil
    if self._created then
        HUD.ClearParent(self.id)
    end
    return self
end

--- Sets whether the element is visible/enabled.
---@param enabled boolean True to show the element, false to hide it
---@return WorldBox Returns self for method chaining
function WorldBox:SetEnabled(enabled)
    self.enabled = enabled
    if self._created then
        HUD.SetEnabled(self.id, enabled)
    end
    return self
end

--- Sets draw order for this world box.
---@param zIndex number Integer draw order
---@return WorldBox Returns self for method chaining
function WorldBox:SetZIndex(zIndex)
    self.z_index = zIndex
    if self._created then
        HUD.SetZIndex(self.id, zIndex)
    end
    return self
end

--- Creates the element in C++ (sends creation request to HUD system).
--- Must be called after configuring all properties.
---@return WorldBox Returns self for method chaining
---@usage marker:Create()
function WorldBox:Create()
    HUD.AddWorldBox({
        id = self.id,
        x = self.x,
        y = self.y,
        z = self.z,
        width = self.width,
        height = self.height,
        color = self.color,
        border_width = self.border_width,
        border_color = self.border_color,
        lifetime_ms = self.lifetime_ms,
        enabled = self.enabled,
        z_index = self.z_index
    })
    
    self._created = true
    if self.parent_id ~= nil then
        HUD.SetParent(self.id, self.parent_id)
    end
    return self
end

--- Removes the element from the world.
---@usage marker:Remove()
function WorldBox:Remove()
    if self._created then
        HUD.RemoveElement(self.id)
        self._created = false
    end
end

--- Checks if the element has been created in C++.
---@return boolean True if element exists in C++
function WorldBox:IsCreated()
    return self._created
end

--- Queries if the element is enabled
---@return boolean
function WorldBox:GetEnabled()
    return HUD.GetElementEnabled(self.id)
end

--- Queries if the element is visible
---@return boolean
function WorldBox:GetVisible()
    return HUD.GetElementVisible(self.id)
end

--- Queries the current color
---@return table Color {r, g, b, a}
function WorldBox:GetColor()
    return HUD.GetElementColor(self.id)
end

--- Queries the current world position
---@return table Position {x, y, z}
function WorldBox:GetPosition()
    return HUD.GetWorldElementPosition(self.id)
end

--- Queries the element width
---@return number Width in pixels
function WorldBox:GetWidth()
    return HUD.GetElementWidth(self.id)
end

--- Queries the element height
---@return number Height in pixels
function WorldBox:GetHeight()
    return HUD.GetElementHeight(self.id)
end

-- ============================================================================
-- SCREEN IMAGE - Image anchored to screen coordinates (2D overlay)
-- ============================================================================

---@class ScreenImage
---@field id string
---@field source string?
---@field item_id number?
---@field item_name string?
---@field width number
---@field height number
---@field source_width number
---@field source_height number
---@field opacity number
---@field smooth boolean
---@field label string
---@field label_color table
---@field label_offset_x number
---@field label_offset_y number
---@field h_align number
---@field v_align number
---@field is_draggable boolean
---@field is_clickable boolean
---@field enabled boolean
---@field z_index number Draw order; higher values render and receive clicks above lower values
---@field parent_id string|nil
---@field screen_x number|nil
---@field screen_y number|nil
---@field _created boolean
---@field _clickCallback function|nil
ScreenImage = {}
ScreenImage.__index = ScreenImage

function ScreenImage:New(id)
    local element = {
        id = id,
        source = nil,
        item_id = nil,
        item_name = nil,
        width = -1.0,
        height = -1.0,
        source_width = -1,
        source_height = -1,
        opacity = 1.0,
        smooth = true,
        label = "",
        label_color = { r = 255, g = 255, b = 255, a = 255 },
        label_offset_x = 0.0,
        label_offset_y = 0.0,
        h_align = HorizontalAlignment.LEFT,
        v_align = VerticalAlignment.TOP,
        is_draggable = false,
        is_clickable = false,
        enabled = true,
        z_index = 0,
        parent_id = nil,
        drag_target_id = nil,
        screen_x = nil,
        screen_y = nil,
        _created = false,
        _clickCallback = nil,
        _dragEndCallback = nil
    }
    setmetatable(element, ScreenImage)
    return element
end

function ScreenImage:SetSource(path)
    self.source = path
    self.item_id = nil
    self.item_name = nil
    return self
end

function ScreenImage:SetItemId(itemId)
    self.item_id = itemId
    self.source = nil
    self.item_name = nil
    return self
end

function ScreenImage:SetItemName(itemName)
    self.item_name = itemName
    self.source = nil
    self.item_id = nil
    return self
end

function ScreenImage:SetSize(width, height)
    self.width = width
    self.height = height
    return self
end

function ScreenImage:SetLabel(text, color, offsetX, offsetY)
    self.label = text or ""
    if type(color) == "table" then
        self.label_color = color
    end
    if type(offsetX) == "number" then
        self.label_offset_x = offsetX
    end
    if type(offsetY) == "number" then
        self.label_offset_y = offsetY
    end
    if self._created and type(HUD.UpdateImageLabel) == "function" then
        HUD.UpdateImageLabel({
            id = self.id,
            label = self.label,
            label_color = self.label_color,
            label_offset_x = self.label_offset_x,
            label_offset_y = self.label_offset_y
        })
    end
    return self
end

function ScreenImage:SetAlignment(h_align, v_align)
    self.h_align = h_align
    self.v_align = v_align
    if self._created then
        HUD.SetAlignment(self.id, h_align, v_align)
    end
    return self
end

function ScreenImage:SetDraggable(draggable)
    self.is_draggable = draggable and true or false
    if self._created then
        HUD.SetDraggable(self.id, self.is_draggable)
    end
    return self
end

--- Makes this image a drag handle for another screen HUD element.
---@param target ScreenText|ScreenImage|string|nil Target element or element id
---@return ScreenImage
function ScreenImage:SetDragTarget(target)
    self.drag_target_id = target == nil and nil or hud_element_id(target, "ScreenImage:SetDragTarget")
    if self._created then
        HUD.SetDragTarget(self.id, self.drag_target_id)
    end
    return self
end

--- Runs after a drag finishes. The callback receives final target x and y coordinates.
---@param callback function|nil Callback function(x, y), or nil to clear it
---@return ScreenImage
function ScreenImage:SetOnDragEnd(callback)
    if callback ~= nil and callback ~= false and type(callback) ~= "function" then
        error("ScreenImage:SetOnDragEnd: callback must be a function, false, or nil")
    end
    self._dragEndCallback = callback or nil
    if self._created then
        HUD.SetOnDragEnd(self.id, self._dragEndCallback)
    end
    return self
end

function ScreenImage:SetClickable(callback)
    if callback == nil or callback == false then
        self.is_clickable = false
        self._clickCallback = nil
        if self._created then
            HUD.SetClickable(self.id, false, nil)
        end
    elseif type(callback) == "function" then
        self.is_clickable = true
        self._clickCallback = callback
        if self._created then
            HUD.SetClickable(self.id, true, callback)
        end
    else
        error("SetClickable: argument must be nil, false, or a function")
    end
    return self
end

--- Sets the screen position in pixels from top-left corner.
--- If called before :Create(), the position is applied immediately after creation.
---@param x number X coordinate in pixels (0 = left edge of screen)
---@param y number Y coordinate in pixels (0 = top edge of screen)
---@return ScreenImage Returns self for method chaining
function ScreenImage:SetScreenPosition(x, y)
    self.screen_x = x
    self.screen_y = y
    if self._created then
        HUD.SetScreenPosition({
            id = self.id,
            x = x,
            y = y
        })
    end
    return self
end

--- Sets the logical parent element for this screen image.
--- Parent visibility/removal cascade to this image, and parent screen movement keeps this image's current offset.
---@param parent ScreenText|ScreenImage|string Parent element or element id
---@return ScreenImage Returns self for method chaining
function ScreenImage:SetParent(parent)
    self.parent_id = hud_element_id(parent, "ScreenImage:SetParent")
    if self._created then
        HUD.SetParent(self.id, self.parent_id)
    end
    return self
end

--- Clears the logical parent relationship for this screen image.
---@return ScreenImage Returns self for method chaining
function ScreenImage:ClearParent()
    self.parent_id = nil
    if self._created then
        HUD.ClearParent(self.id)
    end
    return self
end

function ScreenImage:SetEnabled(enabled)
    self.enabled = enabled and true or false
    if self._created then
        HUD.SetEnabled(self.id, self.enabled)
    end
    return self
end

function ScreenImage:SetZIndex(zIndex)
    self.z_index = zIndex
    if self._created then
        HUD.SetZIndex(self.id, zIndex)
    end
    return self
end

function ScreenImage:Create()
    local payload = {
        id = self.id,
        width = self.width,
        height = self.height,
        source_width = self.source_width,
        source_height = self.source_height,
        opacity = self.opacity,
        smooth = self.smooth,
        label = self.label,
        label_color = self.label_color,
        label_offset_x = self.label_offset_x,
        label_offset_y = self.label_offset_y,
        h_align = self.h_align,
        v_align = self.v_align,
        is_draggable = self.is_draggable,
        is_clickable = self.is_clickable,
        on_click = self._clickCallback,
        enabled = self.enabled,
        z_index = self.z_index
    }

    if type(self.source) == "string" and self.source ~= "" then
        payload.source = self.source
    elseif type(self.item_id) == "number" and self.item_id > 0 then
        payload.item_id = self.item_id
    elseif type(self.item_name) == "string" and self.item_name ~= "" then
        payload.item_name = self.item_name
    else
        error("ScreenImage:Create requires source, item_id, or item_name")
    end

    HUD.AddScreenImage(payload)
    self._created = true
    if type(self.screen_x) == "number" and type(self.screen_y) == "number" then
        HUD.SetScreenPosition({
            id = self.id,
            x = self.screen_x,
            y = self.screen_y
        })
    end
    if self.parent_id ~= nil then
        HUD.SetParent(self.id, self.parent_id)
    end
    if self.drag_target_id ~= nil then
        HUD.SetDragTarget(self.id, self.drag_target_id)
    end
    if self._dragEndCallback ~= nil then
        HUD.SetOnDragEnd(self.id, self._dragEndCallback)
    end
    return self
end

function ScreenImage:Remove()
    if self._created then
        HUD.RemoveElement(self.id)
        self._created = false
    end
end

--- Checks if the element has been created in C++.
---@return boolean
function ScreenImage:IsCreated()
    return self._created
end

---@return boolean
function ScreenImage:GetEnabled()
    return HUD.GetElementEnabled(self.id)
end

---@return boolean
function ScreenImage:GetVisible()
    return HUD.GetElementVisible(self.id)
end

---@return table Position table {x, y, POS_X, POS_Y, POS_y}
function ScreenImage:GetPosition()
    return HUD.GetScreenElementPosition(self.id)
end

---@return number
function ScreenImage:GetWidth()
    return HUD.GetElementWidth(self.id)
end

---@return number
function ScreenImage:GetHeight()
    return HUD.GetElementHeight(self.id)
end

-- ============================================================================
-- WORLD IMAGE - Image anchored to world coordinates
-- ============================================================================

---@class WorldImage
---@field id string
---@field x number
---@field y number
---@field z number
---@field source string?
---@field item_id number?
---@field item_name string?
---@field width number
---@field height number
---@field source_width number
---@field source_height number
---@field opacity number
---@field smooth boolean
---@field label string
---@field label_color table
---@field label_offset_x number
---@field label_offset_y number
---@field lifetime_ms number
---@field offset_x number
---@field offset_y number
---@field enabled boolean
---@field z_index number Draw order; higher values render above lower values
---@field parent_id string|nil
---@field _created boolean
WorldImage = {}
WorldImage.__index = WorldImage

function WorldImage:New(id, x, y, z)
    local element = {
        id = id,
        x = x,
        y = y,
        z = z,
        source = nil,
        item_id = nil,
        item_name = nil,
        width = -1.0,
        height = -1.0,
        source_width = -1,
        source_height = -1,
        opacity = 1.0,
        smooth = true,
        label = "",
        label_color = { r = 255, g = 255, b = 255, a = 255 },
        label_offset_x = 0.0,
        label_offset_y = 0.0,
        lifetime_ms = 0,
        offset_x = 0.0,
        offset_y = 0.0,
        enabled = true,
        z_index = 0,
        parent_id = nil,
        _created = false
    }
    setmetatable(element, WorldImage)
    return element
end

function WorldImage:SetSource(path)
    self.source = path
    self.item_id = nil
    self.item_name = nil
    return self
end

function WorldImage:SetItemId(itemId)
    self.item_id = itemId
    self.source = nil
    self.item_name = nil
    return self
end

function WorldImage:SetItemName(itemName)
    self.item_name = itemName
    self.source = nil
    self.item_id = nil
    return self
end

function WorldImage:SetSize(width, height)
    self.width = width
    self.height = height
    return self
end

function WorldImage:SetPosition(x, y, z)
    self.x = x
    self.y = y
    self.z = z
    if self._created then
        HUD.SetPosition({ id = self.id, x = x, y = y, z = z })
    end
    return self
end

function WorldImage:SetOffset(offsetX, offsetY)
    self.offset_x = offsetX
    self.offset_y = offsetY
    if self._created then
        HUD.UpdateOffset(self.id, offsetX, offsetY)
    end
    return self
end

function WorldImage:SetLifetime(lifetimeMs)
    self.lifetime_ms = lifetimeMs
    if self._created then
        HUD.UpdateLifetime(self.id, lifetimeMs)
    end
    return self
end

--- Sets the logical parent element for this world image.
--- Parent visibility and removal cascade to this image without changing its world position.
---@param parent_id string Parent element id
---@return WorldImage Returns self for method chaining
function WorldImage:SetParent(parent_id)
    self.parent_id = parent_id
    if self._created then
        HUD.SetParent(self.id, parent_id)
    end
    return self
end

--- Clears the logical parent relationship for this world image.
---@return WorldImage Returns self for method chaining
function WorldImage:ClearParent()
    self.parent_id = nil
    if self._created then
        HUD.ClearParent(self.id)
    end
    return self
end

--- Sets whether the world image is visible/enabled.
---@param enabled boolean True to show the element, false to hide it
---@return WorldImage Returns self for method chaining
function WorldImage:SetEnabled(enabled)
    self.enabled = enabled and true or false
    if self._created then
        HUD.SetEnabled(self.id, self.enabled)
    end
    return self
end

function WorldImage:SetZIndex(zIndex)
    self.z_index = zIndex
    if self._created then
        HUD.SetZIndex(self.id, zIndex)
    end
    return self
end

function WorldImage:Create()
    local payload = {
        id = self.id,
        x = self.x,
        y = self.y,
        z = self.z,
        width = self.width,
        height = self.height,
        source_width = self.source_width,
        source_height = self.source_height,
        opacity = self.opacity,
        smooth = self.smooth,
        label = self.label,
        label_color = self.label_color,
        label_offset_x = self.label_offset_x,
        label_offset_y = self.label_offset_y,
        lifetime_ms = self.lifetime_ms,
        offset_x = self.offset_x,
        offset_y = self.offset_y,
        enabled = self.enabled,
        z_index = self.z_index
    }

    if type(self.source) == "string" and self.source ~= "" then
        payload.source = self.source
    elseif type(self.item_id) == "number" and self.item_id > 0 then
        payload.item_id = self.item_id
    elseif type(self.item_name) == "string" and self.item_name ~= "" then
        payload.item_name = self.item_name
    else
        error("WorldImage:Create requires source, item_id, or item_name")
    end

    HUD.AddWorldImage(payload)
    self._created = true
    if self.parent_id ~= nil then
        HUD.SetParent(self.id, self.parent_id)
    end
    return self
end

function WorldImage:Remove()
    if self._created then
        HUD.RemoveElement(self.id)
        self._created = false
    end
end

--- Checks if the element has been created in C++.
---@return boolean
function WorldImage:IsCreated()
    return self._created
end

---@return boolean
function WorldImage:GetEnabled()
    return HUD.GetElementEnabled(self.id)
end

---@return boolean
function WorldImage:GetVisible()
    return HUD.GetElementVisible(self.id)
end

---@return table Position table {x, y, z}
function WorldImage:GetPosition()
    return HUD.GetWorldElementPosition(self.id)
end

---@return number
function WorldImage:GetWidth()
    return HUD.GetElementWidth(self.id)
end

---@return number
function WorldImage:GetHeight()
    return HUD.GetElementHeight(self.id)
end

-- PascalCase aliases for scripting compatibility.
ScreenText = ScreenText
WorldText = WorldText
WorldBox = WorldBox
ScreenImage = ScreenImage
WorldImage = WorldImage

local function attach_method_aliases(target, aliasMap)
    if type(target) ~= "table" then
        return
    end

    for i = 1, #aliasMap do
        local pair = aliasMap[i]
        local canonicalName = pair[1]
        local legacyName = pair[2]
        local canonicalFn = target[canonicalName]

        if type(canonicalFn) == "function" and target[legacyName] == nil then
            target[legacyName] = canonicalFn
        end
    end
end

attach_method_aliases(ScreenText, {
    { "New", "new" },
    { "SetText", "setText" },
    { "SetColor", "setColor" },
    { "SetAlignment", "setAlignment" },
    { "SetDraggable", "setDraggable" },
    { "SetDragTarget", "setDragTarget" },
    { "SetOnDragEnd", "setOnDragEnd" },
    { "SetClickable", "setClickable" },
    { "SetScreenPosition", "setScreenPosition" },
    { "SetParent", "setParent" },
    { "ClearParent", "clearParent" },
    { "SetEnabled", "setEnabled" },
    { "SetZIndex", "setZIndex" },
    { "Create", "create" },
    { "Remove", "remove" },
    { "IsCreated", "isCreated" },
    { "GetEnabled", "getEnabled" },
    { "GetVisible", "getVisible" },
    { "GetText", "getText" },
    { "GetColor", "getColor" },
    { "GetPosition", "getPosition" },
    { "GetWidth", "getWidth" },
    { "GetHeight", "getHeight" }
})

attach_method_aliases(WorldText, {
    { "New", "new" },
    { "SetText", "setText" },
    { "SetColor", "setColor" },
    { "SetOffset", "setOffset" },
    { "SetPosition", "setPosition" },
    { "SetLifetime", "setLifetime" },
    { "SetParent", "setParent" },
    { "ClearParent", "clearParent" },
    { "SetEnabled", "setEnabled" },
    { "SetZIndex", "setZIndex" },
    { "Create", "create" },
    { "Remove", "remove" }
})

attach_method_aliases(WorldBox, {
    { "New", "new" },
    { "SetColor", "setColor" },
    { "SetBorderWidth", "setBorderWidth" },
    { "SetBorderColor", "setBorderColor" },
    { "SetPosition", "setPosition" },
    { "SetSize", "setSize" },
    { "SetLifetime", "setLifetime" },
    { "SetParent", "setParent" },
    { "ClearParent", "clearParent" },
    { "SetEnabled", "setEnabled" },
    { "SetZIndex", "setZIndex" },
    { "Create", "create" },
    { "Remove", "remove" }
})

attach_method_aliases(ScreenImage, {
    { "New", "new" },
    { "SetSource", "setSource" },
    { "SetItemId", "setItemId" },
    { "SetItemName", "setItemName" },
    { "SetSize", "setSize" },
    { "SetLabel", "setLabel" },
    { "SetAlignment", "setAlignment" },
    { "SetDraggable", "setDraggable" },
    { "SetDragTarget", "setDragTarget" },
    { "SetOnDragEnd", "setOnDragEnd" },
    { "SetClickable", "setClickable" },
    { "SetScreenPosition", "setScreenPosition" },
    { "SetParent", "setParent" },
    { "ClearParent", "clearParent" },
    { "SetEnabled", "setEnabled" },
    { "SetZIndex", "setZIndex" },
    { "Create", "create" },
    { "Remove", "remove" },
    { "IsCreated", "isCreated" },
    { "GetEnabled", "getEnabled" },
    { "GetVisible", "getVisible" },
    { "GetPosition", "getPosition" },
    { "GetWidth", "getWidth" },
    { "GetHeight", "getHeight" }
})

attach_method_aliases(WorldImage, {
    { "New", "new" },
    { "SetSource", "setSource" },
    { "SetItemId", "setItemId" },
    { "SetItemName", "setItemName" },
    { "SetSize", "setSize" },
    { "SetPosition", "setPosition" },
    { "SetOffset", "setOffset" },
    { "SetLifetime", "setLifetime" },
    { "SetParent", "setParent" },
    { "ClearParent", "clearParent" },
    { "SetEnabled", "setEnabled" },
    { "SetZIndex", "setZIndex" },
    { "Create", "create" },
    { "Remove", "remove" },
    { "IsCreated", "isCreated" },
    { "GetEnabled", "getEnabled" },
    { "GetVisible", "getVisible" },
    { "GetPosition", "getPosition" },
    { "GetWidth", "getWidth" },
    { "GetHeight", "getHeight" }
})



