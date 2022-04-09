import Necryptolis from "../../contracts/Necryptolis.cdc"


transaction(plotId: UInt64, toDate: String) {    
    let necryptolisCollection: &Necryptolis.Collection

    prepare(account: AuthAccount) {
        self.necryptolisCollection = account.borrow<&Necryptolis.Collection>(from: Necryptolis.CollectionStoragePath) 
        ?? panic("Could not borrow a reference to the Necryptolis collection")
    }

    execute {
        let plot = self.necryptolisCollection.borrowCemeteryPlot(id: plotId) ?? panic("No plot with given ID in users collection.")
        plot.setToDate(toDate: toDate);
    }
}