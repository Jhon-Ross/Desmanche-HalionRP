-- Inicializar cfg se não existir
if not cfg then
    cfg = {}
end

cfg.desmanche = {

	{
		-- desmanche Geral
		iniciar = { -2544.27,2540.8,7.95 }, 
        desmanchar = { -2547.22,2538.59,7.42 }, 
        ferramentas = { -2541.9,2539.99,7.95 }, 
        anunciar = { -2544.4,2538.15,7.42 }, 
        computador = { -2544.55,2538.78,7.42 },
		server = {
			restrito = true,
			permissions = {
				"desmanche.permissao"
			},
			itens = {
				{'chave', 1},
			}
		}
    },
	
	{	---['x'] = 2531.05, ['y'] = 4123.44, ['z'] = 40.63, ['h'] = 248.75
		-- desmanche REDROSE
		iniciar = { 2529.82,4122.28,38.59 }, 
        desmanchar = { 2524.05,4115.45,38.59 }, 
        ferramentas = { 2519.67,4118.13,38.59 }, 
        anunciar = { 2529.82,4122.28,38.59 }, 
        computador = { 2529.82,4122.28,38.59 },
		server = {
			restrito = true,
			permissions = {
				"redroses.permissao"
			},
			itens = {
				{'chave', 1},
			}
		}
    },

	{
		-- desmanche vipers
		iniciar = { 2000.79,3042.04,46.99 }, 
        desmanchar = { 1999.4,3042.86,46.99 }, 
        ferramentas = { 1999.97,3040.79,46.99 }, 
        anunciar = { 1998.16,3044.93,46.99 }, 
        computador = { 1998.55, 3045.50, 47.87, 336.03 },
		server = {
			restrito = true,
			permissions = {
				"vipers.permissao"
			},
			itens = {
				{'chave', 1},
			}
		}
    },

}
