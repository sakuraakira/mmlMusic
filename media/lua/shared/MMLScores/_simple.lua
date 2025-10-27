local MMLScores = require("MMLScores")
MMLScores.register('MMLSheet.simple',
  function()
    return {
      name = "simple",
      mml = {
        melody = {
          mml1 = "t120l4cdefgab>c",
          mml2 = "",
          mml3 = "",
        },
        harmony = {
          mml1 = "t120<l4cdefgab>c",
          mml2 = "",
          mml3 = "",
        },
        accompaniment = {
          mml1 = "t120l4c2e2g2c2ddccee",
          mml2 = "",
          mml3 = "",
        },
        orchestra = {
          mml1 = "t120l4g2b2d+2g+2ffegg",
          mml2 = "",
          mml3 = "",
        },
        bassline = {
          mml1 = "",
          mml2 = "",
          mml3 = "",
        },

      },
    }
  end)
