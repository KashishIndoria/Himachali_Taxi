const express = require('express');
const router = express.Router();
const ratingController = require('../controllers/ratingController');
//console.log('Imported ratingController: ',ratingController);
const  protect  = require('../middleware/authMiddleware');

router.post('/', protect, ratingController.submitRating);

router.get('/driver/:driverId', ratingController.getDriverRatings);

router.get('/my-ratings', protect, ratingController.getMyRatings);

module.exports = router;