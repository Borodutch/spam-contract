import { ethers, upgrades } from 'hardhat'
import { expect } from 'chai'

describe('Spam contract tests', () => {
  let Spam, spam, owner

  before(async function () {
    ;[owner] = await ethers.getSigners()
    Spam = await ethers.getContractFactory('Spam')
    spam = await upgrades.deployProxy(Spam, [
      owner.address,
      '$SPAM',
      'SPAM',
      ethers.parseUnits('1000', 18),
      1,
      ethers.parseUnits('1000000', 18),
      ethers.ZeroAddress,
    ])
  })

  describe('Initialization', function () {
    it('should have correct initial values', async function () {
      expect(await spam.name()).to.equal('$SPAM')
      expect(await spam.symbol()).to.equal('SPAM')
    })
  })
})
