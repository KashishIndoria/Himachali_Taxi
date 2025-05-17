const Ride = require('../models/rides/rides');

exports.updateLocation = async (req, res) => {
    try {
        const { userId, role, rideId, latitude, longitude,} = req.body;
         
        if(!rideId){
            return res.status(400).json({ status :'error', message: 'Ride ID is required' });
        }

        const ride = await Ride.findById(rideId);
        if(!ride){
            return res.status(404).json({ status :'error', message: 'Ride not found' });
        }

        const locationUpdate = {
            latitude,
            longitude,
            lastUpdated: new Date()
        };

        if(role ==='captain'){
            ride.captainLocation = locationUpdate;
        }else{
            ride.userLocation = locationUpdate;
        }

        await ride.save();
        return res.status(200).json({ status :'success', message: 'Location updated successfully' });
    }
    catch(err){
        console.log(err);
        return res.status(500).json({ status :'error', message: 'Failed to update location' });
    }
};

exports.getLocation = async (req, res) => {
    try{
        const {rideId} = req.params;
        const ride = await Ride.findById(rideId);
        if(!ride){
            return res.status(404).json({ status :'error', message: 'Ride not found' });
        }

        return res.status(200).json({ status :'success', data: {
            userLocation: ride.userLocation,
            captainLocation: ride.captainLocation
        }});
    }catch(err){
        console.log(err);
        return res.status(500).json({ status :'error', message: 'Failed to get location' });
    }
};