const aws = require('aws-sdk');
const Pusher = require('pusher');

const S3_BUCKET = process.env.S3_BUCKET;
const S3_FILENAME = process.env.S3_FILENAME;
const PUSHER_APP_ID = process.env.PUSHER_APP_ID;
const PUSHER_KEY = process.env.PUSHER_KEY;
const PUSHER_SECRET = process.env.PUSHER_SECRET;
const PUSHER_CHANNEL = process.env.PUSHER_CHANNEL;
const PUSHER_EVENT = process.env.PUSHER_EVENT;

const s3 = new aws.S3();
const pusher = new Pusher({
  appId: PUSHER_APP_ID,
  key: PUSHER_KEY,
  secret: PUSHER_SECRET,
  encrypted: true
});

exports.handler = (event, context, callback) => {
  const doorId = event['doorId'];
  const doorStatus = event['doorStatus'] === 1 ? 'Open' : 'Closed';
  console.log(`Attempting update of door ${doorId} to status ${doorStatus}`);

  readS3File(S3_BUCKET, S3_FILENAME)
  .then(doorData => {
    console.log(JSON.stringify(doorData));
    const matchingIndex = doorData.findIndex(door => door.id === doorId);

    if (matchingIndex === -1) {
      throw new Error(`Could not find door with id ${doorId}`);
    }
    const door = doorData[matchingIndex];
    console.log(`Moving status of door ${door.id} from ${door.status} to ${doorStatus}`);
    door.status = doorStatus;
    return writeS3File(S3_BUCKET, S3_FILENAME, doorData);
  })
  .then(data => {
    return triggerPusherUpdate(PUSHER_CHANNEL, PUSHER_EVENT, {
      doorId: doorId, doorStatus: doorStatus
    })
      .then(() => callback(null, data));

    callback(null, data);
  })
  .catch(err => {
    console.error(err);
    callback(err, err.message);
  });
};

function triggerPusherUpdate(channel, event, data) {
  console.log(`Sending ${channel}.${event} with payload ${JSON.stringify(data)}`);
  return new Promise((resolve, reject) => {
    pusher.trigger(channel, event, data, function(err) {
      if (err) {
        return reject(err);
      }

      resolve(true);
    });
  });
}

function writeS3File(bucket, path, data) {
  console.log(`Writing S3 data: ${JSON.stringify(data)}`);
  return new Promise((resolve, reject) => {
    s3.putObject({
      Bucket: bucket,
      Key: path,
      Body: new Buffer(JSON.stringify(data), 'utf-8'),
      ACL: 'public-read'
    }, function(error, result) {
      if (error) {
        return reject(error);
      }

      try {
        resolve(data);
      } catch(e) {
        reject(e);
      }
    })
  });
}

function readS3File(bucket, path) {
  console.log(`Reading ${bucket}/${path} from S3`);
  return new Promise((resolve, reject) => {
    s3.getObject({
      Bucket: bucket,
      Key: path
    }, function(error, data) {
      if (error) {
        return reject(error);
      }

      try {
        resolve(JSON.parse(data.Body.toString()));
      } catch(e) {
        reject(e);
      }
    });
  });
}
