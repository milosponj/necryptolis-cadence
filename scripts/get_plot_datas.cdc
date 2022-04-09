import Necryptolis from "../../contracts/Necryptolis.cdc"


pub fun main(): {Int32: {Int32: {UInt64: Necryptolis.PlotData}}} {    
    return Necryptolis.plotDatas
}