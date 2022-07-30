import path from "path";
import { emulator, init } from "flow-js-testing";
import { deployNecryptolis, mintCemeteryPlot } from "../src/necryptolis";
import { getNecryptolisAdminAddress, sleep, toUFix64 } from "../src/common";
import fs from "fs";

// Increase timeout if your tests failing due to timeout
jest.setTimeout(10000);

describe("Necryptolis", () => {
  let adminAddress = "";
  let plots = [];
  // Instantiate emulator and path to Cadence files
  beforeEach(async () => {
    const basePath = path.resolve(__dirname, "../../");
    const port = 8080;
    await init(basePath, port);

    await emulator.start(port, false);

    await deployNecryptolis();

    adminAddress = await getNecryptolisAdminAddress();

    fs.readFile("./files/initial_section.txt", "utf8", (err, data) => {
      if (err) throw err;
      plots = JSON.parse(data);
    });

    return await new Promise((r) => setTimeout(r, 1000));
  });

  // Stop emulator, so it could be restarted
  afterEach(async () => {
    await emulator.stop();
    await new Promise((resolve) => setTimeout(resolve, 100));
  });

  it.skip("shall mint new cemetery plots", async () => {
    var errors = [];
    var success = [];
    for (let index = 0; index < plots.length; index++) {
      const plot = plots[index];
      const mintTransactionRes = await mintCemeteryPlot(
        plot.left,
        plot.top,
        plot.width,
        plot.height,
        adminAddress
      );
      mintTransactionRes.plot = plot;
      if (mintTransactionRes[1] != null) {
        mintTransactionRes[1].plot = plot;
        errors.push(mintTransactionRes[1]);
      } else {
        success.push(mintTransactionRes[0]);
      }
    }

    expect(errors).toEqual([]);
    expect(success.length).toEqual(plots.length);
  }, 170000);
});
