const VideoCall = require('../models/VideoCall');
const { io } = require('../config/socket');

class VideoCallController {
    // Initiate a video call
    async initiateCall(req, res) {
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
    }

    // End a video call
    async endCall(req, res) {
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
    }

    // Get call history
    async getCallHistory(req, res) {
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
    }

    // Get current active call
    async getCurrentCall(req, res) {
        try {
            const call = await VideoCall.findOne({
                $or: [
                    { initiator: req.user.id },
                    { recipient: req.user.id }
                ],
                status: { $in: ['initiated', 'connected'] }
            })
            .populate('initiator recipient', 'name email')
            .populate('ride');

            if (!call) {
                return res.status(404).json({
                    success: false,
                    error: 'No active call found'
                });
            }

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
    }
}

module.exports = new VideoCallController(); 