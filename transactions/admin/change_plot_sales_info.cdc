import FungibleToken from 0x01
import Necryptolis from 0x03
import FUSD from 0x05

transaction(squarePixelPrice: UFix64, candlePrice: UFix64, trimPrice: UFix64, maxPlotHeight: UInt16, maxPlotWidth: UInt16, minPlotHeight: UInt16, minPlotWidth: UInt16) {     
    let adminRef: &Necryptolis.Admin
    let adminFusdVaultCapability: Capability<&AnyResource{FungibleToken.Receiver}>

    prepare(signer: AuthAccount) {
        self.adminRef = signer.borrow<&Necryptolis.Admin>(from: Necryptolis.NecryptolisAdminStoragePath)
            ?? panic("Could not borrow a reference to Necryptolis.Admin")
        self.adminFusdVaultCapability = getAccount(signer.address)
            .getCapability<&FUSD.Vault{FungibleToken.Receiver}>(/public/fusdReceiver)                        
    }

    execute {
      self.adminRef.changePlotSalesInfo(
      squarePixelPrice: squarePixelPrice, 
      candlePrice: candlePrice, 
      trimPrice: trimPrice,
      maxPlotHeight: maxPlotHeight, 
      maxPlotWidth: maxPlotWidth,
      minPlotHeight: minPlotHeight, 
      minPlotWidth: minPlotWidth, 
      vault: self.adminFusdVaultCapability)
    }
}