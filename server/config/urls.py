from flask import Blueprint, render_template
from apps.single_reward.views import (
    random_status,
    status,
    hello_world
)
from apps.core.contants import BaseURL

main = Blueprint('main', __name__)

main.route(f'{BaseURL.BASE_URL}/random_status')(random_status)
main.route(f'{BaseURL.BASE_URL}/status')(status)
main.route('/')(hello_world)


