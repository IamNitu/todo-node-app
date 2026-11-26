require("dotenv").config();

const mongoose = require("mongoose");
const app = require("./app");
const connectDB = require("./config/database");

const PORT = process.env.PORT || 3000;

connectDB()
  .then(() => {
    const server = app.listen(PORT, () => {
      console.log(`Server running on port ${PORT}`);
    });

    let shuttingDown = false;

    const shutdown = (signal) => {
      if (shuttingDown) return;
      shuttingDown = true;
      console.log(`${signal} received. Closing the server gracefully...`);

      const forceExitTimer = setTimeout(() => {
        console.error("Graceful shutdown timed out; forcing process exit.");
        process.exit(1);
      }, 10000);
      forceExitTimer.unref();

      server.close(async (serverError) => {
        if (serverError) {
          console.error("Error while closing the HTTP server:", serverError);
        }

        try {
          await mongoose.disconnect();
          console.log("MongoDB connection closed.");
        } catch (error) {
          console.error("Error while closing MongoDB:", error.message);
          process.exitCode = 1;
        } finally {
          clearTimeout(forceExitTimer);
          if (serverError) process.exitCode = 1;
        }
      });
    };

    process.once("SIGTERM", () => shutdown("SIGTERM"));
    process.once("SIGINT", () => shutdown("SIGINT"));
  })
  .catch((error) => {
    console.error("Failed to start server:", error.message);
    process.exit(1);
  });
