-- (c) 2024 Jacek Olszak
-- This code is licensed under MIT license (see LICENSE for details)

function attach_tree(gui, el)
  local bg_color = 7
  local fg_color = 13
  local highlight_bg_color = 1
  local highlight_fg_color = 7

  local node_height = 10

  local nodes_by_id = {}

  el.draw = function() end  -- needed for scrollbars clipping
  local container = gui:attach(el)
  local root_node = container:attach({ width = el.width, height = node_height, x = 0, y = 0 })
  root_node.indent = ""
  container:attach_scrollbars { autohide = true }

  function container:add_child(id, text, parent_id)
    local parent
    if parent_id == nil then
      parent = root_node
    else
      parent = nodes_by_id[parent_id]
    end


    local child = parent:attach({ width = parent.width, height = node_height, x = 0, y = parent.height })
    child.text = text
    child.indent = parent.indent .. "  "
    if parent_id == nil then
      child.indent = "" -- root element should not have an indent
    end
    function child:draw(msg)
      if msg.mx > 0 and msg.mx < self.width and msg.my > 0 and msg.my < node_height then
          pal(bg_color,highlight_bg_color);pal(fg_color,highlight_fg_color)
        end
      local prefix = "[-] "
      if #child.child == 0 then
        prefix = "    "
      end
      rectfill(0,0,self.width,node_height,bg_color)
      print(child.indent .. prefix .. self.text, 0, 1, fg_color)
      pal()
    end

    function child:click()
      el:select { id = id }
      return true
    end

    local function add_height(parent, h)
      parent.height += h
      if parent._parent != nil then
        add_height(parent._parent, h)
      end
    end

    add_height(parent, node_height)

    child._parent = parent -- use _parent beause parent is already used by Picotron
    nodes_by_id[id] = child
  end

  function container:draw()
    rectfill(0, 0, container.width, container.height, bg_color)
  end

  function container:update_child_text(id, text)
    nodes_by_id[id].text = text
  end

  function container:reset()
    for _, child in ipairs(root_node.child) do
      child:detach()
    end
    root_node.y = 0
    root_node.height = node_height
    root_node.height = 0
  end

  return container
end
