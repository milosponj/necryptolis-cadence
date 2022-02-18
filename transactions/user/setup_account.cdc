import FungibleToken from 0x01
import NonFungibleToken from 0x02
import FUSD from 0x05
import Necryptolis from 0x03

  pub fun hasFUSD(_ address: Address): Bool {
    let receiver = getAccount(address)
      .getCapability<&FUSD.Vault{FungibleToken.Receiver}>(/public/fusdReceiver)
      .check()
    let balance = getAccount(address)
      .getCapability<&FUSD.Vault{FungibleToken.Balance}>(/public/fusdBalance)
      .check()
    return receiver && balance
  }

  pub fun hasCollection(_ address: Address): Bool {
    return getAccount(address)
      .getCapability<&Necryptolis.Collection{NonFungibleToken.CollectionPublic, Necryptolis.NecryptolisCollectionPublic}>(Necryptolis.CollectionPublicPath)
      .check()
  }

  transaction {
    prepare(acct: AuthAccount) {
     
        if acct.borrow<&FUSD.Vault>(from: /storage/fusdVault) == nil {
            acct.save(<-FUSD.createEmptyVault(), to: /storage/fusdVault)
        }
        acct.unlink(/public/fusdReceiver)
        acct.unlink(/public/fusdBalance)
        acct.link<&FUSD.Vault{FungibleToken.Receiver}>(/public/fusdReceiver, target: /storage/fusdVault)
        acct.link<&FUSD.Vault{FungibleToken.Balance}>(/public/fusdBalance, target: /storage/fusdVault)
      
        if acct.borrow<&Necryptolis.Collection>(from: Necryptolis.CollectionStoragePath) == nil {
          acct.save(<-Necryptolis.createEmptyCollection(), to: Necryptolis.CollectionStoragePath)
        }
         acct.unlink(Necryptolis.CollectionPublicPath)
         acct.link<&Necryptolis.Collection{NonFungibleToken.CollectionPublic, Necryptolis.NecryptolisCollectionPublic}>(Necryptolis.CollectionPublicPath, target: Necryptolis.CollectionStoragePath)
    

      if acct.borrow<&Necryptolis.PlotMinter>(from: Necryptolis.PlotMinterStoragePath) == nil {
          acct.save(<-Necryptolis.createPlotMinter(), to: Necryptolis.PlotMinterStoragePath)
      }
    }
  }