import Necryptolis from "../../contracts/Necryptolis.cdc"

transaction(newURL: String) {     
    let adminRef: &Necryptolis.Admin?
    prepare(signer: AuthAccount) {
        self.adminRef = signer.borrow<&Necryptolis.Admin>(from: Necryptolis.NecryptolisAdminStoragePath) ?? panic("No Admin in acct storage")                  
    }

    execute {
        self.adminRef!.changeImagesBaseUrl(baseUrl: newURL) 
    }
}