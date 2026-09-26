-- (c) 2024 Jacek Olszak
-- This code is licensed under MIT license (see LICENSE for details)

-- creates an object which slows down the code if it runs too fast
function new_throttler(max_per_frame)
   local fps <const> = 60
   local instructions_per_second = 8000000 -- max no of instructions in Picotron

   local started, count

   local function reset()
      started = time()
      count = 0
   end

   reset()

   local throttler <const> = {}

   function throttler:throttle()
      count += 1
      if count > max_per_frame and
          count / (time() - started) / fps > max_per_frame
      then
         -- sleep for a frame
         for i = 1, instructions_per_second / fps do end
         reset()
      end
   end

   return throttler
end
