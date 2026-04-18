
# Marshmallow schemas for request/response validation


from marshmallow import Schema, fields, validate, ValidationError, pre_load


# BASKET SCHEMAS


class BatchCreateSchema(Schema):
    """Schema for creating a basket"""
    device_id = fields.Str(
        required=True,
        validate=validate.Length(min=2, max=50),
        error_messages={"required": "device_id is required"}
    )
    fruit_type = fields.Str(
        required=True,
        validate=validate.Length(min=2, max=50)
    )
    location = fields.Str(
        required=True,
        validate=validate.Length(min=2, max=100)
    )
    created_by = fields.Int(required=False, allow_none=True)

    @pre_load
    def strip_whitespace(self, data, **kwargs):
        """Strip whitespace from string fields"""
        for field_name in ['device_id', 'fruit_type', 'location']:
            if field_name in data and isinstance(data[field_name], str):
                data[field_name] = data[field_name].strip()
        return data


class BatchResponseSchema(Schema):
    """Schema for basket response"""
    basket_id = fields.Int()
    device_id = fields.Str()
    fruit_type = fields.Str()
    location = fields.Str()
    created_by = fields.Int(allow_none=True)


class BatchDetailSchema(Schema):
    """Schema for detailed batch response with device and predictions"""
    batch = fields.Nested(BatchResponseSchema)
    assigned_device = fields.Dict(allow_none=True)
    latest_sensor = fields.Dict(allow_none=True)
    latest_prediction = fields.Dict(allow_none=True)



# DEVICE SCHEMAS


class DeviceAssignSchema(Schema):
    """Schema for assigning device to batch"""
    device_id = fields.Str(
        required=False,
        validate=validate.Length(min=2, max=50)
    )
    device_code = fields.Str(
        required=False,
        validate=validate.Length(min=2, max=50)
    )

    def validate_device_identifier(self, data, **kwargs):
        """Ensure either device_id or device_code is provided"""
        if not data.get('device_id') and not data.get('device_code'):
            raise ValidationError("Provide device_id or device_code")


class DeviceResponseSchema(Schema):
    """Schema for device response"""
    device_id = fields.Str()
    wifi_ssid = fields.Str(allow_none=True)
    is_active = fields.Bool()



# SENSOR READING SCHEMAS


class SensorReadingCreateSchema(Schema):
    """Schema for creating sensor reading"""
    device_id = fields.Str(
        required=True,
        validate=validate.Length(min=2, max=50)
    )
    batch_id = fields.Int(
        required=False,
        allow_none=True,
        validate=validate.Range(min=1)
    )
    temp = fields.Float(
        required=True,
        validate=validate.Range(min=-40, max=60)
    )
    hum = fields.Float(
        required=True,
        validate=validate.Range(min=0, max=100)
    )
    eco2 = fields.Float(
        required=True,
        validate=validate.Range(min=0, max=10000)
    )
    tvoc = fields.Float(
        required=True,
        validate=validate.Range(min=0, max=10000)
    )
    aqi = fields.Float(
        required=True,
        validate=validate.Range(min=0, max=1000)
    )
    mq_raw = fields.Float(
        required=True,
        validate=validate.Range(min=0)
    )
    mq_volts = fields.Float(
        required=True,
        validate=validate.Range(min=0)
    )


class SensorReadingResponseSchema(Schema):
    """Schema for sensor reading response"""
    read_id = fields.Int()
    device_id = fields.Str()
    basket_id = fields.Int(allow_none=True)
    temp = fields.Float()
    hum = fields.Float()
    eco2 = fields.Float()
    tvoc = fields.Float()
    aqi = fields.Float()
    mq_raw = fields.Float()
    mq_volts = fields.Float()
    recorded_at = fields.DateTime(format='iso')



# PREDICTION SCHEMAS


class PredictionResponseSchema(Schema):
    """Schema for prediction response"""
    id = fields.Int()
    reading_id = fields.Int()
    device_id = fields.Int()
    batch_id = fields.Int(allow_none=True)
    spoilage_label = fields.Str()
    estimated_days_left = fields.Float(allow_none=True)
    confidence_score = fields.Float(allow_none=True)
    model_version = fields.Str(allow_none=True)
    predicted_at = fields.DateTime(format='iso')



# INSTANTIATE SCHEMAS


batch_create_schema = BatchCreateSchema()
batch_response_schema = BatchResponseSchema()
batch_detail_schema = BatchDetailSchema()

device_assign_schema = DeviceAssignSchema()
device_response_schema = DeviceResponseSchema()

sensor_reading_create_schema = SensorReadingCreateSchema()
sensor_reading_response_schema = SensorReadingResponseSchema()

prediction_response_schema = PredictionResponseSchema()