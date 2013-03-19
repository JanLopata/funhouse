FOURDIRS = ROT.DIRS['4']

window.DIRS =
    UP: FOURDIRS[0]
    RIGHT: FOURDIRS[1]
    DOWN: FOURDIRS[2]
    LEFT: FOURDIRS[3]

window.DIRNAME = (d) ->
    for name, [dx, dy] of DIRS
        if d[0] == dx and d[1] == dy
            return name

symbols =
  #  'LURD'      _=blank r=regular b=bold d=double
  ' ':'____',
  '╴':'r___', '╸':'b___',
  '╵':'_r__', '╹':'_b__',
  '╶':'__r_', '╺':'__b_',
  '╷':'___r', '╻':'___b',
  '┘':'rr__', '┛':'bb__', '┙':'br__', '┚':'rb__',
  '─':'r_r_', '━':'b_b_', '╾':'b_r_', '╼':'r_b_',
  '┐':'r__r', '┓':'b__b', '┑':'b__r', '┒':'r__b',
  '└':'_rr_', '┗':'_bb_', '┖':'_br_', '┕':'_rb_',
  '│':'_r_r', '┃':'_b_b', '╿':'_b_r', '╽':'_r_b',
  '┌':'__rr', '┏':'__bb', '┍':'__br', '┎':'__rb',
  '┴':'rrr_', '┻':'bbb_', '┵':'brr_', '┸':'rbr_', '┶':'rrb_',
  '┺':'rbb_', '┷':'brb_', '┹':'bbr_',
  '┤':'rr_r', '┫':'bb_b', '┥':'br_r', '┦':'rb_r', '┧':'rr_b',
  '┨':'rb_b', '┪':'br_b', '┩':'bb_r',
  '┬':'r_rr', '┳':'b_bb', '┭':'b_rr', '┮':'r_br', '┰':'r_rb',
  '┲':'r_bb', '┱':'b_rb', '┯':'b_br',
  '├':'_rrr', '┣':'_bbb', '┞':'_brr', '┝':'_rbr', '┟':'_rrb',
  '┢':'_rbb', '┠':'_brb', '┡':'_bbr',
  '┼':'rrrr', '╋':'bbbb', '┽':'brrr', '╀':'rbrr', '┾':'rrbr', '╁':'rrrb',
  '╊':'rbbb', '╈':'brbb', '╉':'bbrb', '╇':'bbbr',
  '╂':'rbrb', '┿':'brbr', '╃':'bbrr', '╄':'rbbr', '╆':'rrbb', '╅':'brrb',
  '═':'d_d_', '║':'_d_d',
  '╝':'dd__', '╚':'_dd_', '╔':'__dd', '╗':'d__d',
  '╜':'rd__', '╘':'_rd_', '╓':'__rd', '╕':'d__r',
  '╛':'dr__', '╙':'_dr_', '╒':'__dr', '╖':'r__d',
  '╩':'ddd_', '╠':'_ddd', '╦':'d_dd', '╣':'dd_d',
  '╨':'rdr_', '╞':'_rdr', '╥':'r_rd', '╡':'dr_r',
  '╧':'drd_', '╟':'_drd', '╤':'d_dr', '╢':'rd_d',
  '╬':'dddd', '╪':'drdr', '╫':'rdrd'

symbolLookups = {}
for key, val of symbols
    # remap to ROT.DIRS
    val = val.substr(1) + val.substr(0, 1)

    assert(symbolLookups[val] is undefined)
    symbolLookups[val] = key

extend(symbolLookups, {
    'd___': '║'
    '_d__': '═'
    '__d_': '║'
    '___d': '═'
})

mirrorPlanes =
    '═': [DIRS.UP, DIRS.DOWN]
    '║': [DIRS.LEFT, DIRS.RIGHT]


window.BoxDrawing =
    symbols: symbols
    symbolLookups: symbolLookups
    mirrorPlanes: mirrorPlanes
