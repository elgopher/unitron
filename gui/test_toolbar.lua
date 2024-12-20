-- (c) 2024 Jacek Olszak
-- This code is licensed under MIT license (see LICENSE for details)

---@param el {x:number,y:number,width:number,height:number,start_test:function,stop_test:function,is_running:function}
function attach_toolbar(parent, el)
   local toolbar_color <const> = 6
   local disabled_color <const> = 13
   local enabled_color <const> = 0
   local icon_color <const> = 8

   el = parent:attach(el)
   function el:draw()
      rectfill(0, 0, self.width, self.height, toolbar_color)
   end

   local run_btn <const> = el:attach_button { x = 6, y = 4, width = 10 }
   function run_btn:click()
      if not el.is_running() then
         el.start_test()
      end
   end

   function run_btn:update()
      if el.is_running() then
         self.cursor = nil
      else
         self.cursor = "pointer"
      end
   end

   function run_btn:draw()
      local col = disabled_color
      if not el.is_running() then
         col = enabled_color
      end
      pal(icon_color, col)
      spr(0)
      pal()
   end

   local stop_btn <const> = el:attach_button { x = 22, y = 4, width = 10 }
   function stop_btn:click()
      el.stop_test()
   end

   function stop_btn:update()
      if not el.is_running() then
         self.cursor = nil
      else
         self.cursor = "pointer"
      end
   end

   function stop_btn:draw()
      local col = disabled_color
      if el.is_running() then
         col = enabled_color
      end
      pal(icon_color, col)
      spr(1)
      pal()
   end

   -- local toggle_btn <const> = toolbar:attach_button { x = 35, y = 4, width = 10 }
   -- function toggle_btn:draw()
   -- 	pal(icon_color, enabled_color)
   -- 	spr(2)
   -- 	pal()
   -- end

   return el
end
