import Necryptolis from "../../contracts/Necryptolis.cdc"


pub fun main(left: Int32, top: Int32, width: UInt16, height: UInt16): UFix64 {    
    return Necryptolis.getPlotPrice(width: width, height: height, left: left, top: top, )
}