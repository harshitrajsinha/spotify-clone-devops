import mongoose from "mongoose";

export const connectDB = async () => {
	try {
		const conn = await mongoose.connect(process.env.MONGODB_URI, {
        dbName: "spotify", tls: true, tlsCAFile: "/app/certs/global-bundle.pem", replicaSet: "rs0", readPreference: "secondaryPreferred", retryWrites: false, authMechanism: "SCRAM-SHA-1"
    });
		console.log(`Connected to MongoDB ${conn.connection.host}`);
	} catch (error) {
		console.log("Failed to connect to MongoDB", error);
		process.exit(1); // 1 is failure, 0 is success
	}
};
