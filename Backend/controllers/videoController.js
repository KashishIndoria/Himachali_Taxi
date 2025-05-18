const VideoCall = require('../models/VideoCall');
const SafetyVideo = require('../models/SafetyVideo');
const TrainingVideo = require('../models/TrainingVideo');
const { io } = require('../config/socket');

// Video Call Controllers
exports.initiateVideoCall = async (req, res) => {
    try {
        const { recipientId, rideId } = req.body;
        const call = new VideoCall({
            initiator: req.user.id,
            recipient: recipientId,
            ride: rideId,
            status: 'initiated'
        });
        await call.save();

        // Emit socket event to recipient
        io.to(recipientId).emit('incoming-call', {
            callId: call._id,
            initiator: req.user.id,
            rideId
        });

        res.status(200).json({
            success: true,
            data: call
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
};

exports.endVideoCall = async (req, res) => {
    try {
        const { callId } = req.body;
        const call = await VideoCall.findById(callId);
        
        if (!call) {
            return res.status(404).json({
                success: false,
                error: 'Call not found'
            });
        }

        call.status = 'ended';
        call.endTime = Date.now();
        await call.save();

        // Emit socket event to both parties
        io.to(call.initiator).to(call.recipient).emit('call-ended', { callId });

        res.status(200).json({
            success: true,
            data: call
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
};

// Safety Video Controllers
exports.uploadSafetyVideo = async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({
                success: false,
                error: 'Please upload a video file'
            });
        }

        const safetyVideo = new SafetyVideo({
            title: req.body.title,
            description: req.body.description,
            videoUrl: req.file.path,
            uploadedBy: req.user.id
        });

        await safetyVideo.save();

        res.status(201).json({
            success: true,
            data: safetyVideo
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
};

exports.getSafetyVideos = async (req, res) => {
    try {
        const videos = await SafetyVideo.find()
            .populate('uploadedBy', 'name email')
            .sort('-createdAt');

        res.status(200).json({
            success: true,
            data: videos
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
};

// Training Video Controllers
exports.uploadTrainingVideo = async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({
                success: false,
                error: 'Please upload a video file'
            });
        }

        const trainingVideo = new TrainingVideo({
            title: req.body.title,
            description: req.body.description,
            category: req.body.category,
            videoUrl: req.file.path,
            uploadedBy: req.user.id
        });

        await trainingVideo.save();

        res.status(201).json({
            success: true,
            data: trainingVideo
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
};

exports.getTrainingVideos = async (req, res) => {
    try {
        const { category } = req.query;
        const query = category ? { category } : {};

        const videos = await TrainingVideo.find(query)
            .populate('uploadedBy', 'name email')
            .sort('-createdAt');

        res.status(200).json({
            success: true,
            data: videos
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
};

exports.getVideoCallHistory = async (req, res) => {
    try {
        const calls = await VideoCall.find({
            $or: [
                { initiator: req.user.id },
                { recipient: req.user.id }
            ]
        })
        .populate('initiator recipient', 'name email')
        .populate('ride')
        .sort('-createdAt');

        res.status(200).json({
            success: true,
            data: calls
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
}; 