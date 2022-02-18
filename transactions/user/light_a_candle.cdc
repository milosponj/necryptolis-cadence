import Necryptolis from 0x03
import FUSD from 0x05
import NonFungibleToken from 0x02

transaction(address: Address, cemeteryPlotId: UInt64) {
  let mainFusdVault: &FUSD.Vault?
  let buyerAddress: Address

  prepare(acct: AuthAccount) {    
    self.mainFusdVault = acct.borrow<&FUSD.Vault>(from: /storage/fusdVault) ?? panic("No FUSD vault in acct storage")
    self.buyerAddress = acct.address
  }

  execute {   
    let candlePrice = Necryptolis.plotSalesInfo.candlePrice
    let paymentVault <- self.mainFusdVault!.withdraw(amount: candlePrice)        

    let account = getAccount(address)

    let collectionRef = account.getCapability(Necryptolis.CollectionPublicPath).borrow<&{Necryptolis.NecryptolisCollectionPublic}>()
        ?? panic("Could not borrow capability from public collection")
    collectionRef.lightCandle(cemeteryPlotId: cemeteryPlotId, buyerPayment: <- paymentVault, buyerAddress: self.buyerAddress)
  }
  
}
