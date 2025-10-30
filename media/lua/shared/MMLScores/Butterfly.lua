local MMLScores = require("MMLScores")
MMLScores.register('MMLSheet.Butterfly',
  function()
    return {
      name = "Butterfly",
      mml = {
        melody = {
          mml1 =
          "t165l1.rrrrrrrrr2.l8rv14g+g+bbbbg+g+>c+4<b2rf+g+4bbbbg+g+>c+4d+2<g+f+g+f+e2c+eg4f+ea4gf+e2&er1r4.g+g+bbbbg+g+>c+4<b2rg+g+4bbbbg+g+>c+4d+2<g+f+g+f+e2eeg4f+ea4gf+e2&er1rg+g+g+>e4d+4c+<b4g+2.g+f+g+f+eec+ef+g+a4g+2g+g+g+>e4d+4c+<b4g+2&g+r8g+g+a4g+ab4abb+4b>cd2&dc-1r2.rc-l4e.f+.g+f+g+8f+l8ed+e2.&ec+eg+f+f+eeef+e2e4d+c+<b4g+g+>c+2c+ec+ec+ec+c+g+4g+f+4el4.f+ef+g+4f+4l8g+f+4ed+e2.&ec+eg+f+f+f+bd+d+e2e4d+c+<b4b>f+e2rl1ede&er.r.r.r.l8<g+bbbbg+g+>c+4<b2rg+g+4bbbbg+g+>c+4d+2<g+f+g+f+e2c+eg4f+ea4gf+e2&er1r4.g+4bbbb4g+>c+4<b2rg+g+4bbb4g+g+>c+4d+2<g+f+g+f+e2eeg4f+ea4gf+e2&er1rg+g+g+>e4d+4c+<b4g+2.g+f+g+f+eec+ef+g+a4g+2g+g+g+>e4d+4c+<b4g+2.g+g+a4g+ab4abb+4b>cd2&dc-1r2.rc-l4e.f+.g+f+g+8f+l8ed+e2.&ec+eg+f+f+eeef+e2e4d+c+<b4g+g+>c+2c+ec+ec+ec+c+g+4g+f+4el4.f+ef+g+4f+4l8g+f+4ed+e2.&ec+eg+f+f+f+bd+d+e2e4d+c+<b4b>f+E2Rl1ede&el1.rrrrrrrrrrrrrrrrrr4.C-8l4e.f+.g+f+g+8f+l8ed+e2.&ec+eg+f+F+eeef+E2e4d+c+<b4g+g+>c+2c+ec+ec+ec+c+g+4g+f+4el4.f+ef+g+4f+4l8g+f+4ed+e2.&ec+eg+f+f+f+bd+d+e2e4d+c+<b4g+>f+E2Re1d1l4e.f+.g+f+g+8f+l8ed+e2.&ec+eg+f+4eeef+E2e4d+c+<b4g+g+>c+2c+ec+ec+ec+c+g+4g+f+4el4.f+ef+g+4f+4l8g+f+4ed+e2.&ec+eg+f+f+f+bd+d+e2e4d+c+<b4g+>f+E2Rl1ede&e&e",
          mml2 =
          "v11l1.rrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr2.l8ra1&a4c-4ce.g.ba2.&al16agl8.f+ga8ded8d2.&d8c4&c16c-c8l4<bag+.a.b2l16&ba8b>cd8ef+g8al4.ba>d1&d4r8e2.&e8f+ga4b1&b8l8.bbbbl8ae2",
          mml3 = "",
        },
        accompaniment = {
          mml1 =
          "v11l1rrrrrg+4.l8g+16A16g+f+e4f+4.a2&ag+4.g+16A16g+f+e4f+4.d2&dg+4.g+16A16g+f+e4f+4.a2&ag+4.g+16A16g+f+e4f+4.d2&do2e4r1.f+16r16g+4r1.rg+4ar2rb>g4gga4al4a<eg8g+8e8g8g+8el8ef+egeg+4e4l16ererererererererererererf+rl4g+r1.rar2r8b8>gg8g8aa8a<eg8g+8e8g8g+8el8ef+egeg+4>>el16c+rn44re8c+rn44re8c+rd+8<brg+r>d+8<brg+r>d+8c-rc+8<arer>c+8<arer>c+8<arb8g+rerb8g+rerb8g+r>e8c+rn44re8c+rn44re8c+rd+8<brg+r>d+8<brg+r>d+8<bre4.l2f+gal8&af+1&f+>barab4.g+r4g+r4g+rf+r4f+r4f+rg+r4g+r4g+rf+r4f+r4f+rar4ar4ag+4g+g+e4ee4er4er4erf+r4f+r4f+rg+r4g+r4g+rf+r4f+r4f+rg+r4g+r4g+rf+r4f+r4f+rar4ar4ag+4g+g+e4ee4g1a1g+4.g+16A16g+f+e4f+4.a2&ag+4.g+16A16g+f+e4f+4.d2&dg+4.g+16A16g+f+e4f+4.a2&ag+4.g+16A16g+f+e4f+4.d2&d<<e4r1.f+16r16g+4r1.rg+4ar2rb>g4gga4al4a<eg8g+8e8g8g+8el8ef+egeg+4e4l16ererererererererererererf+rl4g+r1.rar2r8b8>gg8g8aa8a<eg8g+8e8g8g+8el8ef+egeg+4>el16c+rn44re8c+rn44re8c+rd+8<brg+r>d+8<brg+r>d+8c-rc+8<arer>c+8<arer>c+8<arb8g+rerb8g+rerb8g+r>e8c+rn44re8c+rn44re8c+rd+8<brg+r>d+8<brg+r>d+8<bre4.l2f+gal8&af+1r>>barab4.<g+r4g+r4g+rf+r4f+r4f+rg+r4g+r4g+rf+r4f+r4f+rar4ar4ag+4g+g+e4ee4er4er4erf+r4f+r4f+rg+r4g+r4g+rf+r4f+r4f+rg+r4g+r4g+rf+r4f+r4f+rar4ar4ag+4g+g+e4ee4l1garrrre&ef+&f+l16brbrbrbrbrbrbrbrbrbrbrbrbrbrbrbrbrbrbrbrbrbrbrbrbrbrbrbrl8ed+dc+l1c&cd&dl16brbrbrbrbrbrbrbrbrbrbrbrbrbrbrbrbrbrbrbrbrbrbrbrbrbrbrbrbrbrbrbrarararararararara+ra+ra+ra+ra+ra+ra+ra+rbrbrbrbrbrbrbrbr>c+rc+rc+rc+rc+rc+rc+rc+rd+rd+rd+rd+rd+rd+rd+rd+rd+rd+rd+rd+rd+rd+rd+rd+rd+rd+rd+rd+rd+rd+rd+rd+rd+rl8barab4.g+r4g+r4g+rf+r4f+r4f+rg+r4g+r4g+rf+r4f+r4f+rar4ar4ag+4g+g+e4ee4er4er4erf+r4f+r4f+rg+r4g+r4g+rf+r4f+r4f+rg+r4g+r4g+rf+r4f+r4f+rar4ar4ag+4g+g+e4ee4g1a1g+r4g+r4g+rf+r4f+r4f+rg+r4g+r4g+rf+r4f+r4f+rar4ar4ag+4g+g+e4ee4er4er4erf+r4f+r4f+rg+r4g+r4g+rf+r4f+r4f+rg+r4g+r4g+rf+r4f+r4f+rar4ar4ag+4g+g+e4ee4g1a1g+4.g+16a16g+f+e4f+4.a2&ag+4.g+16a16g+f+e4f+4.d2&dg+4.g+16a16g+f+e4f+4.a2&ag+4.g+16a16g+f+e4f+4.d1&d2&d<g+abe4.",
          mml2 =
          "t165v11r1ee16r8.ee16r8.d8n42c+.<f+g+g+16r8.g+g+16r8.f+8>d<e.>dee16r8.ee16r8.d8n42c+.n42ee16r8.ee16r8.d8n42c+.n42ee16r8.ee16r8.d8n42c+.n42ee16r8.ee16r8.d8n42c+.n42l1.rrrrrrrrrrrrrrrrb8l16f+ef+8b8f+ef+8b8f+eb8l1.rrrrrrrrrrrl4r.ee16r8.ee16r8.d8n42c+.n42ee16r8.ee16r8.d8n42c+.n42ee16r8.ee16r8.d8n42c+.n42ee16r8.ee16r8.d8n42c+.n42l1.rrrrrrrrrrrrrrrrb8l16f+ef+8b8f+ef+8b8f+eb8l1.rrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrl4r.e<g+16r8.>ee16r8.d8n42c+.n42ee16r8.ee16r8.d8n42c+.n42ee16r8.ee16r8.d8n42c+.n42ee16r8.ee16r8.d8n42c+.<f+1&f+",
          mml3 =
          "v11r1<g+g+16r8.g+g+16r8.f+8>d<e.>dee16r8.ee16r8.d8n42c+.<f+g+g+16r8.g+g+16r8.f+8>d<e.>d<g+g+16r8.g+g+16r8.f+8>d<e.>d<g+g+16r8.g+g+16r8.f+8>d<e.>d<g+g+16r8.g+g+16r8.f+8>d<e.>dl1.rrrrrrrrrrrrrrrrrrrrrrrrrrrrl4<g+g+16r8.g+g+16r8.f+8>d<e.>d<g+g+16r8.g+g+16r8.f+8>d<e.>d<g+g+16r8.g+g+16r8.f+8>d<e.>d<g+g+16r8.g+g+16r8.f+8>d<e.>dl1.rrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrl4n44e16r8.<g+g+16r8.f+8>d<e.>d<g+g+16r8.g+g+16r8.f+8>d<e.>d<g+g+16r8.g+g+16r8.f+8>d<e.>d<g+g+16r8.g+g+16r8.f+8>d<e.>d1&d",
        },
        harmony = {
          mml1 = "",
          mml2 = "",
          mml3 = "",
        },
        orchestra = {
          mml1 =
          "t165v11l1.rrrrrrrrrrrrrrrrrrrrrrrrrrl4g+.a.bab8al8g+f+g+2.&g+eg+bb4bbbg+g+2.&g+r1r1r1l4rg+.a.bab8al8g+f+g+2.&g+eg+bbbbn63g+g+a2r1.rl1gf+g+&g+l1.rrrrrrrrrrrrrrrrrrrrrr2l4g+.a.bab8al8g+f+g+2.&g+eg+bb4bbbg+g+2.&g+r1r1r1l4rg+.a.bab8al8g+f+g+2.&g+eg+bbbbn63g+g+a2r1.rl1gf+g+&g+l1.rrrrrrrrrrrrrrrrrr2l4g+.a.bab8al8g+f+g+2.&g+eg+bb4bbbg+g+2.&g+r1r1r1l4rg+.a.bab8al8g+f+g+2.&g+eg+bbbbn63g+g+a2r1.rg1f+1l4g+.a.bab8al8g+f+g+2.&g+eg+bb4bbbg+g+2.&g+r1r1r1l4rg+.a.bab8al8g+f+g+2.&g+eg+bbbbn63g+g+a2r1.rl1gf+g+&g+&g+",
          mml2 =
          "v10l1rrrrr<errrrrr>d4.c+4.<a4rrrrr.l4r.ee8g8g+8e8g8g+8el8ef+egeg+4l1rrrrr.l4r.ee8g8g+8e8g8g+8el8ef+egeg+4>>g+2.&g+f+1&f+e2.&ee1&eg+2.&g+f+1&f+l1rrrr<<eb>c+d+ee4.c+2&c+8<abeb>c+d+c+c-4.c+2&c+8cd<errrrrr>d4.c+4.<a4rrrrr.l4r.ee8g8g+8e8g8g+8el8ef+egeg+4l1rrrrr.l4r.ee8g8g+8e8g8g+8el8ef+egeg+4>>g+2.&g+f+1&f+e2.&ee1&eg+2.&g+f+1&f+l1rrrr<<eb>c+d+ee4.c+2&c+8<abeb>c+d+c+c-4.c+2&c+8cdl4<eg8G+8e8g8G+8el8ef+egel4g+eg8G+8e8g8G+8eE8F+8G8>E<rl1>RRRRRR2R2RRRRRRb&b2a2g+&g+<<ab>c+c+d+&d+d+&d+4r2.<eb>c+d+ee4.c+2&c+8<abeb>c+d+c+c-4.c+2&c+8cd<eb>c+d+ee4.c+2&c+8<abeb>c+d+c+c-4.c+2&c+8cd<errrrrrl4.>dc+<a1&a4>g+8a8b8e",
          mml3 =
          "v12l1rrrrr>e4rrr.r4e4rr.l4r>d.c+.<ael1.rrrrrr2r2.l8rg+a.r16ag+.r1r4r16g+a.r16ag+.r1r16e2f+2&f+16l1.rrrrrr2r16c+4.d+2e2f+2&f+8d+1&d+8rrrrrrrrrrr8l16>gec<g<ceg>c>gec<g<f+df+a>d<a>df+af+a>df+df+al1rrrr<e4rr.l4r>d.c+.<ael1.rrrrrr2r2.l8rg+a.r16ag+.r1r4r16g+a.r16ag+.r1r16e2f+2&f+16l1.rrrrrr2r16c+4.d+2e2f+2&f+8d+1&d+8rrrrrrrrrrr8l16>gec<g<ceg>c>gec<g<f+df+a>d<a>df+af+a>df+df+ar1r1r1.e8.r2rl8v14<edrerf+rgree4g4r4f+erf+rgrarf+l4f+abr1.ag+r1r1l8edrerf+rgree4g4r4f+erf+rgrarf+l4f+abr1.ag+2l8deg4e4ee2&er4c+4c+<abg+af+e4d<bg+4bg+f+a>c+ec+4e4d+.l16f+g+af+8g+8b8n61b8>ec+e8f+g+f+8g+ag+8aba8b>c+8.<b2&bl4g+b8g+b8g+b2.l1.rrrrrrrrrrrrrrrrrrrrr2l16>gec<g<ceg>c>gec<g<f+df+a>d<a>df+af+a>df+df+al1rrrr<e4rr.r4l4.>dc+<a1&a4g+8a8b8e",
        },
        bassline = {
          mml1 =
          "T165V14l1ro2e&ee&el8<eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee>dddc+c+c+<aaeeeeeeee4eeeeef+g+4g+g+g+g+g+g+g+4g+g+g+g+g+g+4aaaaaab>c4ccd4dd<e4eg4eg4e4ef+egeg+4eeeeeeee4eeeeef+g+4g+g+g+g+g+g+g+4g+g+g+g+g+g+a4aaaaab>c4ccd4dd<e4eg4eg4e4ef+eg+eb4>c+c+ec+g+ec+<g+4g+bg+n27bg+baan25a>ec+<ae4ef+eg+ebg+>c+c+ec+g+ec+<g+4g+bg+n27bg+ba>c+ec-4d+f+c4egd4f+a4<bbbbbbbbbr2r>e4<eeeeeeeebbbbbbbb>c+c+c+c+c+c+c+c+<g+g+g+g+g+g+g+g+aaaaaaa>e4eec+4c+c+<eaaaaaaaabbn27b>ec-f+<beeeeeeeebbbbbb>ccc+c+c+c+c+c+c+c+<g+g+g+g+g+g+g+g+aaaaaaag+4g+g+>c+4c+c+c-ccccccccddddd<g+4.eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee>dddc+c+c+<aaeeeeeeee4eeeeef+g+4g+g+g+g+g+g+g+4g+g+g+g+g+g+4aaaaaab>c4ccd4dd<e4eg4eg4e4ef+egeg+4eeeeeeee4eeeeef+g+4g+g+g+g+g+g+g+4g+g+g+g+g+g+a4aaaaab>c4ccd4dd<e4eg4eg4e4ef+eg+eb4>c+c+ec+g+ec+<g+4g+bg+n27bg+baan25a>ec+<ae4ef+eg+ebg+>c+c+ec+g+ec+<g+4g+bg+n27bg+ba>c+ec-4d+f+c4egd4f+a4<bbbbbbbbbr2r>e4<eeeeeeeebbbbbbbb>c+c+c+c+c+c+c+c+<g+g+g+g+g+g+g+g+aaaaaaa>e4eec+4c+c+<eaaaaaaaabbn27b>ec-f+<beeeeeeeebbbbbb>ccc+c+c+c+c+c+c+c+<g+g+g+g+g+g+g+g+aaaaaaag+4g+g+>c+4c+c+c-ccccccccdddddl4<g+.eg8G+8e8g8G+8el8ef+egel4g+eg8G+8e8g8G+8ege8er>c1&c2.l8&ccd1&d1<eeeeeeeeeeeeeeeeeeeeeeeeeeee>ed+dc+c1&c2.&ccd1&d1<eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeef+f+f+f+f+f+f+f+g+g+g+g+g+g+g+g+aaaaaaaaa+a+a+a+a+a+a+a+bbbbbbbbbbbbbbbbbb4bb4bbb4r2.eeeeeeeebbbbbbbb>c+c+c+c+c+c+c+c+<g+g+g+g+g+g+g+g+aaaaaaa>e4eec+4c+c+<eaaaaaaaabbn27b>ec-f+<beeeeeeeebbbbbb>ccc+c+c+c+c+c+c+c+<g+g+g+g+g+g+g+g+aaaaaaag+4g+g+>c+4c+c+c-ccccccccddddd<g+4.eeeeeeeebbbbbbbb>c+c+c+c+c+c+c+c+<g+g+g+g+g+g+g+g+aaaaaaa>e4eec+4c+c+<eaaaaaaaabbn27b>ec-f+<beeeeeeeebbbbbb>ccc+c+c+c+c+c+c+c+<g+g+g+g+g+g+g+g+aaaaaaag+4g+g+>c+4c+c+c-ccccccccddddd<g+4.eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee>dddc+c+c+<a1&a4g+abe4.",
          mml2 = "",
          mml3 = "",
        },

      },
    }
  end)
