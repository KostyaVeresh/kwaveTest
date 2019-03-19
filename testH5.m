clearvars;

% Локальный путь до исполняемого файла k-wave (здесь CUDA, можно скачать версию для C++/OpenMP)
kspaceFirstOrder3D_CUDA_Path = '"C:\Program Files\MATLAB\R2016b\toolbox\k-Wave\binaries\kspaceFirstOrder3D-CUDA"';

% Директория, где у меня сохраняются/загружаются hdf5 файлы
dirPath = 'D:\Documents\Matlab scripts\WFI\';
inputFile = 'input_data.h5';
outputFile = 'output_data.h5';

% Параметры сетки; Ось Z тут нужна, т.к. с++ код работает только с
% трёхмерными моделями, поэтому для двухмерного моделирования берём
% минимально возможный Nz
Nx = 64;
Ny = 64;
Nz = 2;
dx = 0.1e-3;
dy = 0.1e-3;
dz = 0.1e-3;
kgrid = kWaveGrid(Nx, dx, Ny, dy, Nz, dz);

% Параметры среды (квадратный объект, погружённый в жидкость)
medium.sound_speed = 1480 * ones(Nx, Ny, Nz);
medium.sound_speed(20 : 44, 20 : 44, :) = 2500;
medium.density = 1000 * ones(Nx, Ny, Nz);
medium.density(20 : 44, 20 : 44, :) = 1200;

medium.alpha_power = 1.5;
medium.alpha_coeff = zeros(Nx, Ny, Nz);
medium.alpha_coeff(20 : 44, 20 : 44, :) = 1.7;

kgrid.setTime(510, 1.2e-8);

% Параметры источника (частота, сигнал, местоположение)
source_freq = 1.4e6;
source.p = 5 * toneBurst(1 / kgrid.dt, source_freq, 1);
source.p_mask = false(Nx, Ny, Nz);
source.p_mask(Nx, 32, :) = 1;

% Параметры сенсоров
sensor.mask = false(Nx, Ny, Nz);
sensor.mask(Nx, 1 : 2 : Ny, 1) = 1;
sensor.record = {'p'};

% Параметры поглощающих границ
input_params = {'PMLInside', false ...
              , 'PMLSize', [20, 20, 0]};

% Сохранение модели в виде hdf5-файла
kspaceFirstOrder3D(kgrid, medium, source, sensor, input_params{:}, 'SaveToDisk', [dirPath inputFile]);

% Запускаем c++ (из имён директорий и флагов формируем команду для терминала)
system([kspaceFirstOrder3D_CUDA_Path ' -i "' dirPath inputFile '" -o "' dirPath outputFile '"']);

% Загружаем полученный hdf5-файл в результирующую матрицу и удаляем hdf5
% файлы
sensor_data.p = h5read([dirPath outputFile], '/p');
delete([dirPath inputFile]);
delete([dirPath outputFile]);

% Для наглядности, выведем какой-нибудь результат, например, срез по x=20
plot(sensor_data.p(20,:));
