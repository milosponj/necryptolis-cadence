import path from "path";
import {
  emulator,
  init,
  getAccountAddress,
  shallPass,
  shallResolve,
  shallRevert,
} from "flow-js-testing";
import {
  addGravestone,
  deployNecryptolis,
  getCemeteryPlots,
  getPlotSalesInfo,
  lightCandle,
  trimGrave,
  mintCemeteryPlot,
  setToDate,
  getCandles,
  setupNecryptolisOnAccount,
  getTrimmedOnTimestamp,
  buryKittyItem,
  changePlotSalesInfo,
} from "../src/necryptolis";
import { getNecryptolisAdminAddress, sleep, toUFix64 } from "../src/common";
import { getFUSDBalance, mintFUSD } from "../src/fusd";
import {
  deployKittyItems,
  getKittyItemCount,
  mintKittyItem,
  setupKittyItemsOnAccount,
} from "../src/helper";

// Increase timeout if your tests failing due to timeout
jest.setTimeout(10000);

describe("Necryptolis", () => {
  const left = 0;
  const top = 0;
  const height = 300;
  const width = 300;
  let adminAddress = "";

  // Instantiate emulator and path to Cadence files
  beforeEach(async () => {
    const basePath = path.resolve(__dirname, "../../");
    const port = 8080;
    await init(basePath, port);
    await emulator.start(port, false);
    await deployNecryptolis();

    adminAddress = await getNecryptolisAdminAddress();

    return await new Promise((r) => setTimeout(r, 1000));
  });
  // Stop emulator, so it could be restarted
  afterEach(async () => {
    await emulator.stop();
    await new Promise((resolve) => setTimeout(resolve, 100));
  });

  // it("shall deploy Necryptolis contract", async () => {
  //   const deployment = console.log("dde ploy", deployment);

  //   await shallPass(deployment);
  // });

  it("shall not have any cemetery plots at start", async () => {
    await shallResolve(async () => {
      const cemeteryPlots = await getCemeteryPlots();
      expect(cemeteryPlots).toEqual({}, null);
    });
  });

  it("shall mint new cemetery plots", async () => {
    await shallPass(mintCemeteryPlot(left, top, width, height, adminAddress));
    await shallPass(
      mintCemeteryPlot(
        left + width + 1,
        top + height + 1,
        width,
        height,
        adminAddress
      )
    );

    const plots = await getCemeteryPlots();
    expect(plots).toEqual({
      1: { id: 1, height, left, top, width },
      2: {
        id: 2,
        height,
        left: left + width + 1,
        top: top + height + 1,
        width,
      },
    });
  });

  describe("validation", () => {
    it("shall not allow minting a colliding plot", async () => {
      await shallPass(mintCemeteryPlot(left, top, width, height, adminAddress));
      await shallRevert(
        mintCemeteryPlot(
          left + width - 1,
          top + height - 1,
          width,
          height,
          adminAddress
        )
      );
    });

    it("shall not allow minting a plot under the minimum height", async () => {
      const { minPlotHeight, minPlotWidth } = await getPlotSalesInfo();

      await shallRevert(
        mintCemeteryPlot(
          0,
          0,
          minPlotWidth + 1,
          minPlotHeight - 1,
          adminAddress
        )
      );
    });

    it("shall not allow minting a plot under the minimum width", async () => {
      const { minPlotHeight, minPlotWidth } = await getPlotSalesInfo();

      await shallRevert(
        mintCemeteryPlot(
          0,
          0,
          minPlotWidth - 1,
          minPlotHeight + 1,
          adminAddress
        )
      );
    });

    it("shall not allow minting a plot over the maximum height", async () => {
      const { maxPlotHeight, maxPlotWidth } = await getPlotSalesInfo();

      await shallRevert(
        mintCemeteryPlot(
          0,
          0,
          maxPlotWidth - 1,
          maxPlotHeight + 1,
          adminAddress
        )
      );
    });

    it("shall not allow minting a plot over the maximum width", async () => {
      const { maxPlotHeight, maxPlotWidth } = await getPlotSalesInfo();

      await shallRevert(
        mintCemeteryPlot(
          0,
          0,
          maxPlotWidth + 1,
          maxPlotHeight - 1,
          adminAddress
        )
      );
    });
  });

  it("shall add a gravestone to a plot", async () => {
    await mintCemeteryPlot(left, top, width, height, adminAddress);

    await shallPass(addGravestone(1, "New grave"));
  });

  it("shall not allow adding a second gravestone", async () => {
    await mintCemeteryPlot(left, top, width, height, adminAddress);

    await shallPass(addGravestone(1, "New grave"));
    await shallRevert(addGravestone(1, "New grave 2"));
  });

  it("shall set the toDate after gravestone is created", async () => {
    await mintCemeteryPlot(left, top, width, height, adminAddress);

    await addGravestone(1, "New grave");
    await shallPass(setToDate(1, "1/1/2001"));
  });

  it("shall not allow setting the toDate if it's already set", async () => {
    await mintCemeteryPlot(left, top, width, height, adminAddress);

    await addGravestone(1, "New grave", "01/01/2020", "01/01/2021");
    await shallRevert(setToDate(1, "2/2/2002"));
  });

  it("shall light a candle", async () => {
    const Alice = await getAccountAddress("Alice");
    const ress = await setupNecryptolisOnAccount(Alice);

    await mintFUSD(Alice, 10.0);

    await mintCemeteryPlot(left, top, width, height, Alice);

    await shallPass(lightCandle(Alice, Alice, 1));
    await shallPass(lightCandle(Alice, Alice, 1));

    const fusdBalance = await getFUSDBalance(Alice);
    const candles = await getCandles(Alice, 1);

    expect(candles.length).toEqual(2);
    expect(candles[0]).toMatchObject({ buyerAddress: Alice });
    expect(fusdBalance[0]).toEqual(toUFix64(8));
  });

  it("shall allow trimming the grave", async () => {
    const Alice = await getAccountAddress("Alice");
    await setupNecryptolisOnAccount(Alice);

    await mintFUSD(Alice, 10.0);

    await mintCemeteryPlot(left, top, width, height, Alice);

    const firstTrimmed = await getTrimmedOnTimestamp(Alice, 1);

    await sleep(1111);
    await shallPass(trimGrave(Alice, Alice, 1));

    const lastTrimmed = await getTrimmedOnTimestamp(Alice, 1);

    const fusdBalance = await getFUSDBalance(Alice);
    expect(fusdBalance[0]).toEqual(toUFix64(9));
    expect(parseFloat(lastTrimmed)).toBeGreaterThan(parseFloat(firstTrimmed));
  });

  it("shall bury a Kitty Item", async () => {
    const Alice = await getAccountAddress("Alice");
    await setupNecryptolisOnAccount(Alice);
    await mintCemeteryPlot(left, top, width, height, Alice);

    await deployKittyItems(Alice);
    await setupKittyItemsOnAccount(Alice);
    await mintKittyItem(Alice, Alice, 1, 1);

    await shallPass(buryKittyItem(Alice, 1, 0));
  });

  it("shall allow admin to change plot sales info", async () => {
    await shallPass(changePlotSalesInfo(1, 3, 5, 555, 777, 111, 333));

    const plotSalesInfo = await getPlotSalesInfo();
    expect(plotSalesInfo).toMatchObject({
      squarePixelPrice: "1.00000000",
      candlePrice: "3.00000000",
      trimPrice: "5.00000000",
      maxPlotHeight: 555,
      maxPlotWidth: 777,
      minPlotHeight: 111,
      minPlotWidth: 333,
    });
  });
});
