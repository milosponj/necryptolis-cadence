import Necryptolis from 0x03

transaction(plotId: UInt64, name: String, fromDate: String, toDate: String, metadata: {String:String} ) {    
    let necryptolisProvider: Capability<&Necryptolis.Collection{Necryptolis.NecryptolisCollectionPublic}>
    let graveStoneCreator: &Necryptolis.GravestoneManager{Necryptolis.GravestoneCreator}

    prepare(account: AuthAccount) {
        // We need a provider capability, but one is not provided by default so we create one if needed.
        let necryptolisProviderPrivatePath = /private/necryptolisCollectionProvider

        if !account.getCapability<&Necryptolis.Collection{Necryptolis.NecryptolisCollectionPublic}>(necryptolisProviderPrivatePath)!.check() {
            account.link<&Necryptolis.Collection{Necryptolis.NecryptolisCollectionPublic}>(necryptolisProviderPrivatePath, target: Necryptolis.CollectionStoragePath)
        }

        self.necryptolisProvider = account.getCapability<&Necryptolis.Collection{Necryptolis.NecryptolisCollectionPublic}>(necryptolisProviderPrivatePath)!
        
        assert(self.necryptolisProvider.borrow() != nil, message: "Missing or mis-typed Necryptolis Collection provider")

        if account.borrow<&Necryptolis.GravestoneManager>(from: Necryptolis.GravestoneManagerStoragePath) == nil {
          account.save(<-Necryptolis.createGravestoneManager(), to: Necryptolis.GravestoneManagerStoragePath)
        }

        self.graveStoneCreator = account.borrow<&Necryptolis.GravestoneManager>(from: Necryptolis.GravestoneManagerStoragePath)
            ?? panic("Missing or mis-typed GravestoneManager.")
    }

    execute {
        self.graveStoneCreator.createGravestone(
            necryptolisProviderCapability: self.necryptolisProvider, 
            nftID: plotId, 
            graveData: Necryptolis.GraveData(name: name, fromDate: fromDate, toDate: toDate, metadata: metadata)
        )
    }
}