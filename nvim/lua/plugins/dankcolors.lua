-- DankMaterialShell / matugen base16 theme.
-- Machine-local to the Arch + DMS desktop: matugen regenerates this file whenever
-- the wallpaper changes, so it lives in the repo only to survive a fresh clone.
-- Guarded so a machine without DMS (e.g. the Mac Studio) loads nothing and keeps
-- its catppuccin colours.
if
  vim.fn.has("linux") == 0
  or vim.fn.isdirectory(vim.fn.expand("~/.config/DankMaterialShell")) == 0
then
  return {}
end

return {
	{
		"RRethy/base16-nvim",
		-- Same priority as catppuccin; discovered later so base16 wins on DMS.
		priority = 1000,
		config = function()
			require('base16-colorscheme').setup({
				base00 = '#151217',
				base01 = '#151217',
				base02 = '#9b95a1',
				base03 = '#9b95a1',
				base04 = '#f8efff',
				base05 = '#fcf8ff',
				base06 = '#fcf8ff',
				base07 = '#fcf8ff',
				base08 = '#ff9faf',
				base09 = '#ff9faf',
				base0A = '#e7c7ff',
				base0B = '#a5ffbb',
				base0C = '#f2e1ff',
				base0D = '#e7c7ff',
				base0E = '#ebd1ff',
				base0F = '#ebd1ff',
			})

			vim.api.nvim_set_hl(0, 'Visual', {
				bg = '#9b95a1',
				fg = '#fcf8ff',
				bold = true
			})
			vim.api.nvim_set_hl(0, 'Statusline', {
				bg = '#e7c7ff',
				fg = '#151217',
			})
			vim.api.nvim_set_hl(0, 'LineNr', { fg = '#9b95a1' })
			vim.api.nvim_set_hl(0, 'CursorLineNr', { fg = '#f2e1ff', bold = true })

			vim.api.nvim_set_hl(0, 'Statement', {
				fg = '#ebd1ff',
				bold = true
			})
			vim.api.nvim_set_hl(0, 'Keyword', { link = 'Statement' })
			vim.api.nvim_set_hl(0, 'Repeat', { link = 'Statement' })
			vim.api.nvim_set_hl(0, 'Conditional', { link = 'Statement' })

			vim.api.nvim_set_hl(0, 'Function', {
				fg = '#e7c7ff',
				bold = true
			})
			vim.api.nvim_set_hl(0, 'Macro', {
				fg = '#e7c7ff',
				italic = true
			})
			vim.api.nvim_set_hl(0, '@function.macro', { link = 'Macro' })

			vim.api.nvim_set_hl(0, 'Type', {
				fg = '#f2e1ff',
				bold = true,
				italic = true
			})
			vim.api.nvim_set_hl(0, 'Structure', { link = 'Type' })

			vim.api.nvim_set_hl(0, 'String', {
				fg = '#a5ffbb',
				italic = true
			})

			vim.api.nvim_set_hl(0, 'Operator', { fg = '#f8efff' })
			vim.api.nvim_set_hl(0, 'Delimiter', { fg = '#f8efff' })
			vim.api.nvim_set_hl(0, '@punctuation.bracket', { link = 'Delimiter' })
			vim.api.nvim_set_hl(0, '@punctuation.delimiter', { link = 'Delimiter' })

			vim.api.nvim_set_hl(0, 'Comment', {
				fg = '#9b95a1',
				italic = true
			})

			local current_file_path = vim.fn.stdpath("config") .. "/lua/plugins/dankcolors.lua"
			if not _G._matugen_theme_watcher then
				local uv = vim.uv or vim.loop
				_G._matugen_theme_watcher = uv.new_fs_event()
				_G._matugen_theme_watcher:start(current_file_path, {}, vim.schedule_wrap(function()
					local new_spec = dofile(current_file_path)
					if new_spec and new_spec[1] and new_spec[1].config then
						new_spec[1].config()
						print("Theme reload")
					end
				end))
			end
		end
	}
}
