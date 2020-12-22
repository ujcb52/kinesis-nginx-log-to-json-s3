import base64
import json
import re
import datetime

print('Loading function')


def lambda_handler(event, context):
    output = []
    succeeded_record_cnt = 0
    failed_record_cnt = 0

    regex_pattern =  (r'(?P<ipaddress>([^\s]+)) - - '
                  r'\[(?P<timestamp>\d{2}\/[a-z]{3}\/\d{4}:\d{2}:\d{2}:\d{2} (\+|\-)\d{4})\] '
                  r'((\"(GET|POST) )(?P<uri>.+)(http\/1\.1")) (?P<statuscode>\d{3}) (?P<bytessent>\d+) '
                  r'(["](?P<refferer>(\-)|(.+))["]) (["](?P<useragent>.+)["])'
                  )

    lineformat = re.compile(
    regex_pattern, re.IGNORECASE)

    for record in event['records']:
        print(record['recordId'])
        payload = base64.b64decode(record['data']).decode('utf-8')
        data = re.search(lineformat, payload)

        if data:
            succeeded_record_cnt += 1
            datadict = data.groupdict()
            timestamp = format_timestamp_str(datadict["timestamp"])
            data_request = re.sub('"', '', data.group(5))
            data_verb = re.sub('"', '', data.group(6).strip())
            
            data_field = {
                'host':        datadict["ipaddress"],
                'timestamp': timestamp,
                'request':   data_request,
                'uri':       datadict["uri"],
                'status':    datadict["statuscode"],
                'size':      datadict["bytessent"],
                'verb':   data_verb,
                'refferer':  datadict["refferer"],
                'useragent': datadict["useragent"],
            }
            data_field_bytes = json.dumps(data_field).encode('utf-8')
            output_record = {
                'recordId': record['recordId'],
                'result': 'Ok',
                'data': base64.b64encode(data_field_bytes).decode('utf-8')
            }
        else:
            print('Parsing failed')
            failed_record_cnt += 1
            output_record = {
                'recordId': record['recordId'],
                'result': 'ProcessingFailed',
                'data': record['data']
            }

        output.append(output_record)

    print('Processing completed.  Successful records {}, Failed records {}.'.format(succeeded_record_cnt, failed_record_cnt))
    return {'records': output}

def format_timestamp_str(timestamp):
    tmp_tstamp = datetime.datetime.strptime(timestamp, '%d/%b/%Y:%H:%M:%S %z')
    formatted_timestamp = tmp_tstamp.strftime('%Y-%m-%dT%H:%M:%S')
    return formatted_timestamp